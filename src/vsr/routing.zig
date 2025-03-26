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
const constants = @import("../constants.zig");
const stdx = @import("../stdx.zig");

replica: u8,
route: Route,

const Quality = [constants.members_max]u64;

const Route = [constants.members_max]u8;
const Routing = @This();

pub fn route_next(routing: *const Routing, view: u32, op: u64) stdx.BoundedArrayType(u8, 2) {
    _ = op; // autofix
    _ = routing;
    _ = u64;
}

pub fn route_activate(routing: *Routing, route_new: Route) void {
    _ = routing; // autofix
    _ = route_new; // autofix
}

pub fn route_switch(routing: *const Routing) ?Route {
    _ = routing; // autofix
}

pub fn op_repliacted(routing: *Routing, op: u64, latency_ns: u64) void {
    _ = latency_ns; // autofix
    _ = routing; // autofix
    _ = op; // autofix
}

fn route_for_op(routing: *const Routing, op: u64) Route {
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
