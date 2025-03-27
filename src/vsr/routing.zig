//! TigerBeetle replication routing protocol.
//!
//! Eight fallacies of distributed computing:
//!
//! 1. The network is reliable;
//! 2. Latency is zero;
//! 3. Bandwidth is infinite;
//! 4. The network is secure;
//! 5. Topology doesn't change;
//! 6. There is one administrator;
//! 7. Transport cost is zero;
//! 8. The network is homogeneous;
//!
//! Robust tail principle:
//! - The same code should handle slow nodes and crashed nodes.
//! - A single crashed node should not cause retries and risk metastability.
//!
//! Algorithm:
//!
//! The replication route is V-shaped. Primary is in the middle, and it tosses each prepare at two
//! of its neighbors. Backups forward prepares to at most one further backup. Neighbors of the
//! primary have at least one more neighbor (in a six-replica cluster). If any single node fails,
//! the primary still gets a replication quorum. If the primary and backups disagree about the
//! replication route, the primary still gets a replication quorum.
//!
//! Because topology changes, routes are dynamic. The primary broadcasts the current route in the
//! ping message. It's enough if the routing information is only eventually consistent.
//!
//! To select the best route, primary uses outcome-focused explore-exploit approach. Every once in a
//! while the primary tries an alternative route. The primary captures replication latency for a
//! route (that is, the arrival time of prepare_ok messages). If the latency for an alternative
//! route is sufficiently better than current latency, the route is switched.
//!
//! The experiment schedule is defined randomly. All replicas share the same RNG seed, so no
//! coordination is needed to launch an experiment!
const std = @import("std");
const assert = std.debug.assert;
const constants = @import("../constants.zig");
const stdx = @import("../stdx.zig");
const ratio = stdx.PRNG.ratio;

const history_max = constants.pipeline_prepare_queue_max;

replica: u8,
replica_count: u8,
replication_quorum_count: u8,

active: Route,
active_view: u32,
active_cost_ema: ?u64,

best_alternative: ?Route,
best_alterative_cost_avg: ?u64,

history: [history_max]?Latencies,

const Latencies = struct {
    op: u64,
    prepare: u64,
    prepare_ok: [constants.replicas_max]?u64 = .{null} ** constants.replicas_max,
    quorum: ?u64 = null,
    all: ?u64 = null,

    fn record(latencies: *Latencies, quorum: u8, replica: u8, realtime_ns: u64) void {
        assert(replica < constants.replicas_max);
        assert(realtime_ns >= latencies.prepared_ns);
        const latency_ns = realtime_ns - latencies.prepared_ns;

        latencies.per_replica[replica] = latency_ns;
        assert(latencies.max == null or latencies.max < latency_ns);
        latencies.max = latency_ns;

        switch (std.math.order(latencies.count(), quorum)) {
            .lt => assert(latencies.quorum == null),
            .eq => {
                assert(latencies.quorum == null);
                latencies.quorum = latencies.max.?;
            },
            .gt => {
                assert(latencies.quorum != null);
            },
        }
    }

    fn cost(latencies: *Latencies, replica_count: u8) ?u64 {
        const missing_cost = (replica_count - latencies.count) *
            @min(latencies.max.?, std.ns_per_s) * 100;
        const quorum_cost = latencies.quorum * 10;
        const full_cost = latencies.max;

        return missing_cost + quorum_cost + full_cost;
    }

    fn count(latencies: *Latencies) u8 {
        var result: u8 = 0;
        for (latencies.prepare_ok) |l| result += @intFromBool(l != null);
        return result;
    }
};

const Route = [constants.members_max]u8;
const Routing = @This();

const RouteNext = stdx.BoundedArrayType(u8, 2);
pub fn route_next(routing: *const Routing, view: u32, op: u64) RouteNext {
    const route = op_route(view, op);
    const primary: u8 = view % routing.replica_count;
    const index = std.mem.indexOf(u8, route, routing.replica);
    const index_primary = std.mem.indexOf(u8, route, primary);
    if (primary == routing.replica) {
        assert(index == index_primary);
        return RouteNext.from_slice(&.{
            route[index - 1],
            route[index + 1],
        });
    }
    assert(index != index_primary);
    if (index == 0 or index == routing.replica_count - 1) {
        return RouteNext.from_slice(&.{});
    }
    return RouteNext.from_slice(&.{
        route[if (index < index_primary) index - 1 else index + 1],
    });
}

pub fn route_activate(routing: *Routing, view: u32, route: Route) void {
    assert(view >= routing.active_view);
    routing.history_reset();
    routing.active = route;
    routing.active_view = view;
}

pub fn route_improvement(routing: *const Routing) ?Route {
    const alternative = routing.best_alternative orelse return null;
    if (routing.best_alterative_cost_avg >= @divFloor(routing.active_cost_ema *| 9, 10)) {
        return null; // Avoid small improvements so as not to flip routes back and forth.
    }
    return alternative;
}

pub fn op_prepared(routing: *Routing, op: u64, realtime_ns: u64) void {
    if (routing.slot(op).*) |previous| {
        assert(previous.op < op);
        if (!previous.alt) {
            routing.op_finalze(previous, .evicted);
        }
    }

    routing.slot(op).* = .{
        .op = op,
        .prepared = realtime_ns,
    };
}

pub fn op_repliacted(routing: *Routing, op: u64, replica: u8, realtime_ns: u64) void {
    const latencies: *Latencies = if (routing.slot(op).?) |*l| l else {
        // The op was prepared by a different primary in an older view.
        return;
    };
    if (latencies.*.op > op) return;

    latencies.*.record(
        routing.replication_quorum_count,
        replica,
        realtime_ns,
    );
    if (latencies.count() == routing.replica_count) {
        routing.op_finalize(latencies.*, .replicated_fully);
    }
}

fn op_finalize(
    routing: *Routing,
    latencies: Latencies,
    reason: enum { evicted, replicated_fully },
) void {
    if (op_route_alternative(latencies.op)) |alternative| {
        const op_pair = latencies.op ^ 1;
        const latencies_pair = routing.slot(op_pair).* orelse return;
        if (latencies_pair.op != op_pair) return;
        const latencies_a = latencies;
        const latencies_b = latencies_pair;

        if (reason == .evicted and
            latencies_a.count() == routing.replica_count and
            latencies_b.count() == routing.replica_count)
        {
            return;
        }

        const cost_a = latencies_a.cost(routing.replica_count);
        const cost_b = latencies_b.cost(routing.replica_count);
        const cost_avg = @divFloor(cost_a + cost_b, 2);
        if (reason == .evicted or (latencies_a.count() == routing.replica_count and
            latencies_b.count() == routing.replica_count))
        {
            if (routing.best_alterative_cost_avg == null or
                cost_avg < routing.best_alterative_cost_avg.?)
            {
                routing.best_alterative_cost_avg = cost_avg;
                routing.best_alternative = alternative;
            }
        }
    } else {
        if (reason == .evicted and latencies.count() == routing.replica_count) {
            // Already accounted for this on .replicated_fully.
            return;
        }
        const cost = latencies.cost(routing.replica_count).?;
        routing.active_cost_ema = ema_add(
            routing.active_cost_ema,
            cost,
        );
    }
}

fn op_route(routing: *const Routing, view: u32, op: u64) Route {
    if (op_route_alternative(op)) |alternative| {
        return alternative;
    }
    if (view == routing.active_view) {
        return routing.active;
    }
    return op_route_default(view);
}

fn op_route_alternative(op: u64) ?Route {
    const rng = stdx.PRNG.from_seed(op | 1);
    if (rng.chance(ratio(1, 20))) {
        return random_route(&rng);
    }
    return null;
}

fn op_route_default(view: u32) Route {
    _ = view; // autofix
}

fn history_reset(routing: *Routing) void {
    routing.history = .{null} ** routing.replica_count;
    routing.active_cost_ema = null;
}

fn slot(routing: *Routing, op: u64) *?Latencies {
    return &routing.history[op % history_max];
}

fn ema_add(ema: ?u64, next: u64) u64 {
    if (ema == null) return next;
    return @divFloor(ema.? *| 4 +| next, 5);
}

fn random_route(prng: *stdx.PRNG) Route {
    _ = prng; // autofix
}
