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

history: [history_max]Latencies,

const Latencies = struct {
    op: u64,
    prepared_ns: u64,
    per_replica: [constants.replicas_max]?u64,
    quorum: ?u64,
    max: ?u64,
    count: u8,

    fn record(latencies: *Latencies, quorum: u8, replica: u8, realtime_ns: u64) void {
        assert(replica < constants.replicas_max);
        assert(realtime_ns >= latencies.prepared_ns);
        const latency_ns = realtime_ns - latencies.prepared_ns;

        latencies.per_replica[replica] = latency_ns;
        assert(latencies.max == null or latencies.max < latency_ns);
        latencies.max = latency_ns;
        latencies.count += 1;
        assert(latencies.count <= constants.replicas_max);

        switch (std.math.order(latencies.count, quorum)) {
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
};

const Route = [constants.members_max]u8;
const Routing = @This();

const RouteNext = stdx.BoundedArrayType(u8, 2);
pub fn route_next(routing: *const Routing, view: u32, op: u64) RouteNext {
    const route = route_for_op(view, op);
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
    routing.active = route;
    routing.active_view = view;
}

pub fn better_route(routing: *const Routing) ?Route {
    _ = routing; // autofix
}

pub fn op_prepared(routing: *Routing, op: u64, realtime_ns: u64) void {
    assert(routing.history[op % history_max < op]);
    routing.history[op % history_max] = .{
        .op = op,
        .prepared = realtime_ns,
        .per_replica = .{null} ** constants.replicas_max,
        .quorum = null,
        .max = null,
        .count = 0,
    };
}

pub fn op_repliacted(routing: *Routing, op: u64, replica: u8, realtime_ns: u64) void {
    if (routing.history[op % history_max].op > op) return;

    assert(routing.history[op % history_max].op == op);
    routing.history[op % history_max].record(
        routing.replication_quorum_count,
        replica,
        realtime_ns,
    );
}

fn route_for_op(routing: *const Routing, view, op: u64) Route {
    const rng = stdx.PRNG.from_seed(op | 1);
    if (rng.chance(ratio(1, 20))) {
        return random_route(&rng);
    } else {
        return routing.route;
    }
}

fn utility(quality: Quality) u64 {
    _ = quality; // autofix
}

fn random_route(prng: *stdx.PRNG) Route {
    _ = prng; // autofix
}
