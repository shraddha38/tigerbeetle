const std = @import("std");
const builtin = @import("builtin");
const assert = std.debug.assert;

const log = std.log.scoped(.tb_client_context);

const vsr = @import("../tb_client.zig").vsr;

const constants = vsr.constants;
const stdx = vsr.stdx;
const maybe = stdx.maybe;
const Header = vsr.Header;

const IO = vsr.io.IO;
const FIFOType = vsr.fifo.FIFOType;
const message_pool = vsr.message_pool;

const MessagePool = message_pool.MessagePool;
const Message = MessagePool.Message;
const Packet = @import("packet.zig").Packet;
const Signal = @import("signal.zig").Signal;

/// Thread-safe client interface allocated by the user.
/// Contains the `VTable` with function pointers to the StateMachine-specific implementation
/// and the synchronization status.
/// Safe to call from multiple threads, even after `deinit` is called.
pub const ClientInterface = extern struct {
    pub const Error = error{ClientInvalid};
    pub const VTable = struct {
        submit_fn: *const fn (*anyopaque, *Packet.Extern) void,
        completion_context_fn: *const fn (*anyopaque) usize,
        deinit_fn: *const fn (*anyopaque) void,
    };

    /// Magic number used as a tag, preventing the use of uninitialized pointers.
    const beetle: u64 = 0xBEE71E;

    // Since the client interface is an intrusive struct allocated by the user,
    // it is exported as an opaque `[_]u64` array.
    // An `extern union` is used to ensure a platform-independent size for pointer fields,
    // avoiding the need for different versions of `tb_client.h` on 32-bit targets.

    context: extern union {
        ptr: ?*anyopaque,
        int_ptr: u64,
    },
    vtable: extern union {
        ptr: *const VTable,
        int_ptr: u64,
    },
    locker: Locker,
    reserved: u32,
    magic_number: u64,

    pub fn init(self: *ClientInterface, context: *anyopaque, vtable: *const VTable) void {
        self.* = .{
            .context = .{ .ptr = context },
            .vtable = .{ .ptr = vtable },
            .locker = .{},
            .reserved = 0,
            .magic_number = 0,
        };
    }

    pub fn submit(client: *ClientInterface, packet: *Packet.Extern) Error!void {
        if (client.magic_number != beetle) return Error.ClientInvalid;
        assert(client.reserved == 0);

        client.locker.lock();
        defer client.locker.unlock();
        const context = client.context.ptr orelse return Error.ClientInvalid;
        client.vtable.ptr.submit_fn(context, packet);
    }

    pub fn completion_context(client: *ClientInterface) Error!usize {
        if (client.magic_number != beetle) return Error.ClientInvalid;
        assert(client.reserved == 0);

        client.locker.lock();
        defer client.locker.unlock();
        const context = client.context.ptr orelse return Error.ClientInvalid;
        return client.vtable.ptr.completion_context_fn(context);
    }

    pub fn deinit(client: *ClientInterface) Error!void {
        if (client.magic_number != beetle) return Error.ClientInvalid;
        assert(client.reserved == 0);

        const context: *anyopaque = context: {
            client.locker.lock();
            defer client.locker.unlock();
            if (client.context.ptr == null) return Error.ClientInvalid;

            defer client.context.ptr = null;
            break :context client.context.ptr.?;
        };
        client.vtable.ptr.deinit_fn(context);
    }

    comptime {
        assert(@sizeOf(ClientInterface) == 32);
        assert(@alignOf(ClientInterface) == 8);
    }
};

/// The function pointer called by the IO thread when a request is completed or fails.
/// The memory referenced by `result_ptr` is only valid for the duration of this callback.
/// `result_ptr` is `null` for unsuccessful requests. See `packet.status` for more details.
pub const CompletionCallback = *const fn (
    context: usize,
    packet: *Packet.Extern,
    timestamp: u64,
    result_ptr: ?[*]const u8,
    result_len: u32,
) callconv(.C) void;

pub const InitError = std.mem.Allocator.Error || error{
    Unexpected,
    AddressInvalid,
    AddressLimitExceeded,
    SystemResources,
    NetworkSubsystemFailed,
};

/// Implements a `ClientInterface` with specialized `vsr.Client` and `StateMachine` types.
pub fn ContextType(
    comptime Client: type,
) type {
    return struct {
        const Context = @This();

        const StateMachine = Client.StateMachine;
        const allowed_operations = [_]StateMachine.Operation{
            .create_accounts,
            .create_transfers,
            .lookup_accounts,
            .lookup_transfers,
            .get_account_transfers,
            .get_account_balances,
            .query_accounts,
            .query_transfers,
        };

        const UserData = extern struct {
            self: *Context,
            packet: *Packet,

            comptime {
                assert(@sizeOf(UserData) == @sizeOf(u128));
            }
        };

        const PacketError = error{
            TooMuchData,
            ClientShutdown,
            ClientEvicted,
            ClientReleaseTooLow,
            ClientReleaseTooHigh,
            InvalidOperation,
            InvalidDataSize,
        };

        allocator: std.mem.Allocator,
        client_id: u128,

        addresses: stdx.BoundedArrayType(std.net.Address, constants.replicas_max),
        io: IO,
        message_pool: MessagePool,
        client: Client,
        batch_size_limit: ?u32,

        completion_callback: CompletionCallback,
        completion_context: usize,

        interface: *ClientInterface,
        submitted: FIFOType(Packet),
        pending: FIFOType(Packet),

        signal: Signal,
        eviction_reason: ?vsr.Header.Eviction.Reason,
        thread: std.Thread,

        pub fn init(
            allocator: std.mem.Allocator,
            client_out: *ClientInterface,
            cluster_id: u128,
            addresses: []const u8,
            completion_ctx: usize,
            completion_callback: CompletionCallback,
        ) InitError!void {
            var context = try allocator.create(Context);
            errdefer allocator.destroy(context);

            context.allocator = allocator;
            context.client_id = stdx.unique_u128();

            log.debug("{}: init: parsing vsr addresses: {s}", .{ context.client_id, addresses });
            context.addresses = .{};
            const addresses_parsed = vsr.parse_addresses(
                addresses,
                context.addresses.unused_capacity_slice(),
            ) catch |err| return switch (err) {
                error.AddressLimitExceeded => error.AddressLimitExceeded,
                error.AddressHasMoreThanOneColon,
                error.AddressHasTrailingComma,
                error.AddressInvalid,
                error.PortInvalid,
                error.PortOverflow,
                => error.AddressInvalid,
            };
            assert(addresses_parsed.len > 0);
            assert(addresses_parsed.len <= constants.replicas_max);
            context.addresses.resize(addresses_parsed.len) catch unreachable;

            log.debug("{}: init: initializing IO", .{context.client_id});
            context.io = IO.init(32, 0) catch |err| {
                log.err("{}: failed to initialize IO: {s}", .{
                    context.client_id,
                    @errorName(err),
                });
                return switch (err) {
                    error.ProcessFdQuotaExceeded => error.SystemResources,
                    error.Unexpected => error.Unexpected,
                    else => unreachable,
                };
            };
            errdefer context.io.deinit();

            log.debug("{}: init: initializing MessagePool", .{context.client_id});
            context.message_pool = try MessagePool.init(allocator, .client);
            errdefer context.message_pool.deinit(context.allocator);

            log.debug("{}: init: initializing client (cluster_id={x:0>32}, addresses={any})", .{
                context.client_id,
                cluster_id,
                context.addresses.const_slice(),
            });
            context.client = Client.init(
                allocator,
                .{
                    .id = context.client_id,
                    .cluster = cluster_id,
                    .replica_count = context.addresses.count_as(u8),
                    .time = .{},
                    .message_pool = &context.message_pool,
                    .message_bus_options = .{
                        .configuration = context.addresses.const_slice(),
                        .io = &context.io,
                    },
                    .eviction_callback = client_eviction_callback,
                },
            ) catch |err| {
                log.err("{}: failed to initialize Client: {s}", .{
                    context.client_id,
                    @errorName(err),
                });
                return switch (err) {
                    error.TimerUnsupported => error.Unexpected,
                    error.OutOfMemory => error.OutOfMemory,
                    else => unreachable,
                };
            };
            errdefer context.client.deinit(context.allocator);

            ClientInterface.init(client_out, context, comptime &.{
                .submit_fn = &vtable_submit_fn,
                .completion_context_fn = &vtable_completion_context_fn,
                .deinit_fn = &vtable_deinit_fn,
            });
            context.interface = client_out;
            context.submitted = .{
                .name = null,
                .verify_push = builtin.is_test,
            };
            context.pending = .{
                .name = null,
                .verify_push = builtin.is_test,
            };
            context.completion_context = completion_ctx;
            context.completion_callback = completion_callback;
            context.eviction_reason = null;

            log.debug("{}: init: initializing signal", .{context.client_id});
            try context.signal.init(&context.io, Context.signal_notify_callback);
            errdefer context.signal.deinit();

            context.batch_size_limit = null;
            context.client.register(client_register_callback, @intFromPtr(context));

            log.debug("{}: init: spawning thread", .{context.client_id});
            context.thread = std.Thread.spawn(.{}, Context.io_thread, .{context}) catch |err| {
                log.err("{}: failed to spawn thread: {s}", .{
                    context.client_id,
                    @errorName(err),
                });
                return switch (err) {
                    error.Unexpected => error.Unexpected,
                    error.OutOfMemory => error.OutOfMemory,
                    error.SystemResources,
                    error.ThreadQuotaExceeded,
                    error.LockedMemoryLimitExceeded,
                    => error.SystemResources,
                };
            };

            // Setting `magic_number` tags the interface as initialized.
            // Writing it at the end so that if `init` fails part-way through and the
            // user doesn’t handle the error before using it, we'll still be able to validate.
            client_out.magic_number = ClientInterface.beetle;
        }

        fn tick(self: *Context) void {
            if (self.eviction_reason == null) {
                self.client.tick();
            }
        }

        fn io_thread(self: *Context) void {
            while (self.signal.status() != .stopped) {
                self.tick();
                self.io.run_for_ns(constants.tick_ms * std.time.ns_per_ms) catch |err| {
                    log.err("{}: IO.run() failed: {s}", .{
                        self.client_id,
                        @errorName(err),
                    });
                    @panic("IO.run() failed");
                };
            }

            // If evicted, the inflight request was already canceled during eviction.
            if (self.eviction_reason == null) {
                self.cancel_request_inflight();
            }

            while (self.pending.pop()) |packet| {
                packet.assert_phase(.pending);
                self.packet_cancel(packet);
            }

            // The submitted queue is no longer accessible to user threads,
            // so synchronization is not required here.
            while (self.submitted.pop()) |packet| {
                packet.assert_phase(.submitted);
                self.packet_cancel(packet);
            }
        }

        /// Cancel the current inflight packet, as it won't be replied anymore.
        fn cancel_request_inflight(self: *Context) void {
            if (self.client.request_inflight) |*inflight| {
                if (inflight.message.header.operation != .register) {
                    const packet = @as(UserData, @bitCast(inflight.user_data)).packet;
                    packet.assert_phase(.sent);
                    self.packet_cancel(packet);
                }
            }
        }

        /// Calls the user callback when a packet is canceled due to the client
        /// being either evicted or shutdown.
        fn packet_cancel(self: *Context, packet: *Packet) void {
            assert(packet.next == null);
            assert(packet.phase != .complete);
            packet.assert_phase(packet.phase);

            const result = if (self.eviction_reason) |reason| switch (reason) {
                .reserved => unreachable,
                .client_release_too_low => error.ClientReleaseTooLow,
                .client_release_too_high => error.ClientReleaseTooHigh,
                else => error.ClientEvicted,
            } else result: {
                assert(self.signal.status() != .running);
                break :result error.ClientShutdown;
            };

            var it: ?*Packet = packet;
            while (it) |batched| {
                if (batched != packet) batched.assert_phase(.batched);
                it = batched.batch_next;
                self.notify_completion(batched, result);
            }
        }

        fn packet_enqueue(self: *Context, packet: *Packet) void {
            assert(self.batch_size_limit != null);
            packet.assert_phase(.submitted);

            if (self.eviction_reason != null) {
                return self.packet_cancel(packet);
            }

            const operation: StateMachine.Operation = operation_from_int(packet.operation) orelse {
                self.notify_completion(packet, error.InvalidOperation);
                return;
            };

            // Get the size of each request structure in the packet.data.
            // Make sure the packet.data wouldn't overflow a request, and that the corresponding
            // results won't overflow a reply.
            const event_size: usize, const events_batch_max: u32 = switch (operation) {
                .pulse, .get_events => unreachable,
                inline else => |operation_comptime| .{
                    @sizeOf(StateMachine.EventType(operation_comptime)),
                    StateMachine.operation_batch_max(
                        operation_comptime,
                        self.batch_size_limit.?,
                    ),
                },
            };
            assert(self.batch_size_limit.? >= event_size * events_batch_max);

            const events: []const u8 = packet.slice();
            if (events.len % event_size != 0) {
                self.notify_completion(packet, error.InvalidDataSize);
                return;
            }

            if (@divExact(events.len, event_size) > events_batch_max) {
                self.notify_completion(packet, error.TooMuchData);
                return;
            }

            // Avoid making a packet inflight by cancelling it if the client was shutdown.
            if (self.signal.status() != .running) {
                self.packet_cancel(packet);
                return;
            }

            // Nothing inflight means the packet should be submitted right now.
            if (self.client.request_inflight == null) {
                assert(self.pending.count == 0);
                packet.phase = .pending;
                packet.batch_size = packet.data_size;
                packet.batch_allowed = false;
                self.packet_send(packet);
                return;
            }

            const batch_allowed = batch_logical_allowed(
                operation,
                packet.data,
                packet.data_size,
            );

            // If allowed, try to batch the packet with another already in self.pending.
            if (batch_allowed) {
                var it = self.pending.peek();
                while (it) |root| {
                    root.assert_phase(.pending);
                    it = root.next;

                    // Check for pending packets of the same operation which can be batched.
                    if (root.operation != packet.operation) continue;
                    if (!root.batch_allowed) continue;

                    const merged_events = @divExact(root.batch_size + packet.data_size, event_size);
                    if (merged_events > events_batch_max) continue;

                    packet.phase = .batched;
                    if (root.batch_next == null) {
                        assert(root.batch_tail == null);
                        root.batch_next = packet;
                        root.batch_tail = packet;
                    } else {
                        assert(root.batch_tail != null);
                        root.batch_tail.?.batch_next = packet;
                        root.batch_tail = packet;
                    }
                    root.batch_size += packet.data_size;
                    return;
                }
            }

            // Couldn't batch with existing packet so push to pending directly.
            packet.phase = .pending;
            packet.batch_size = packet.data_size;
            packet.batch_allowed = batch_allowed;
            self.pending.push(packet);
        }

        /// Sends the packet (the entire batched linked list of packets) through the vsr client.
        /// Always called by the io thread.
        fn packet_send(self: *Context, packet: *Packet) void {
            assert(self.batch_size_limit != null);
            assert(self.client.request_inflight == null);
            packet.assert_phase(.pending);

            // On shutdown, cancel this packet as well as any others batched onto it.
            if (self.signal.status() != .running) {
                return self.packet_cancel(packet);
            }

            const message = self.client.get_message().build(.request);
            defer {
                self.client.release_message(message.base());
                packet.assert_phase(.sent);
            }

            const bytes_writen: u32 = bytes_writen: {
                // Copy all batched packet event data into the message buffer.
                const buffer: []u8 = message.buffer[@sizeOf(Header)..];
                assert(buffer.len >= packet.batch_size);

                var bytes_writen: u32 = 0;
                var it: ?*Packet = packet;
                while (it) |batched| {
                    if (batched != packet) batched.assert_phase(.batched);
                    it = batched.batch_next;

                    const events: []const u8 = batched.slice();
                    stdx.copy_disjoint(
                        .exact,
                        u8,
                        buffer[bytes_writen..][0..events.len],
                        events,
                    );
                    bytes_writen += @intCast(events.len);
                }
                assert(bytes_writen == packet.batch_size);
                break :bytes_writen bytes_writen;
            };

            const operation: StateMachine.Operation = operation_from_int(packet.operation).?;
            message.header.* = .{
                .release = self.client.release,
                .client = self.client.id,
                .request = 0, // Set by client.raw_request.
                .cluster = self.client.cluster,
                .command = .request,
                .operation = vsr.Operation.from(StateMachine, operation),
                .size = @sizeOf(vsr.Header) + bytes_writen,
            };

            packet.phase = .sent;
            self.client.raw_request(
                Context.client_result_callback,
                @bitCast(UserData{
                    .self = self,
                    .packet = packet,
                }),
                message.ref(),
            );
            assert(message.header.request != 0);
        }

        fn signal_notify_callback(signal: *Signal) void {
            const self: *Context = @alignCast(@fieldParentPtr("signal", signal));
            assert(self.signal.status() != .stopped);

            // Don't send any requests until registration completes.
            if (self.batch_size_limit == null) {
                assert(self.client.request_inflight != null);
                assert(self.client.request_inflight.?.message.header.operation == .register);
                return;
            }

            // Prevents IO thread starvation under heavy client load.
            // Process only the minimal number of packets for the next pending request.
            const enqueued_count = self.pending.count;
            const safety_limit = 8 * 1024; // Avoid unbounded loop in case of invalid packets.
            for (0..safety_limit) |_| {
                const packet: *Packet = pop: {
                    self.interface.locker.lock();
                    defer self.interface.locker.unlock();
                    break :pop self.submitted.pop() orelse return;
                };
                self.packet_enqueue(packet);

                // Packets can be processed without increasing `pending.count`:
                // - If the packet is invalid.
                // - If there's no in-flight request, the packet is sent immediately without
                //   using the pending queue.
                // - If the packet can be batched with another previously enqueued packet.
                if (self.pending.count > enqueued_count) break;
            }

            // Defer this work to later,
            // allowing the IO thread to remain free for processing completions.
            const empty: bool = empty: {
                self.interface.locker.lock();
                defer self.interface.locker.unlock();
                break :empty self.submitted.empty();
            };
            if (!empty) {
                self.signal.notify();
            }
        }

        fn client_register_callback(user_data: u128, result: *const vsr.RegisterResult) void {
            const self: *Context = @ptrFromInt(@as(usize, @intCast(user_data)));
            assert(self.client.request_inflight == null);
            assert(self.batch_size_limit == null);
            assert(result.batch_size_limit > 0);

            // The client might have a smaller message size limit.
            maybe(constants.message_body_size_max < result.batch_size_limit);
            self.batch_size_limit = @min(result.batch_size_limit, constants.message_body_size_max);

            // Some requests may have queued up while the client was registering.
            signal_notify_callback(&self.signal);
        }

        fn client_eviction_callback(client: *Client, eviction: *const Message.Eviction) void {
            const self: *Context = @fieldParentPtr("client", client);
            assert(self.eviction_reason == null);

            log.debug("{}: client_eviction_callback: reason={?s} reason_int={}", .{
                self.client_id,
                std.enums.tagName(vsr.Header.Eviction.Reason, eviction.header.reason),
                @intFromEnum(eviction.header.reason),
            });

            self.eviction_reason = eviction.header.reason;

            self.cancel_request_inflight();
            while (self.pending.pop()) |packet| {
                self.packet_cancel(packet);
            }
        }

        fn client_result_callback(
            raw_user_data: u128,
            operation: StateMachine.Operation,
            timestamp: u64,
            reply: []const u8,
        ) void {
            const user_data: UserData = @bitCast(raw_user_data);
            const self = user_data.self;
            const packet = user_data.packet;
            assert(packet.operation == @intFromEnum(operation));
            assert(timestamp > 0);
            packet.assert_phase(.sent);

            // Submit the next pending packet (if any) now that VSR has completed this one.
            assert(self.client.request_inflight == null);
            while (self.pending.pop()) |packet_next| {
                self.packet_send(packet_next);
                if (self.client.request_inflight != null) break;
            }

            switch (operation) {
                .pulse, .get_events => unreachable,
                inline else => |operation_comptime| {
                    // on_result should never be called with an operation not green-lit by request()
                    // This also guards from passing an unsupported operation into DemuxerType.
                    if (comptime operation_from_int(@intFromEnum(operation_comptime)) == null) {
                        unreachable;
                    }

                    // Demuxer expects []u8 but VSR callback provides []const u8.
                    // The bytes are known to come from a Message body that will be soon discarded
                    // therefore it's safe to @constCast and potentially modify the data in-place.
                    var demuxer = Client.DemuxerType(operation_comptime).init(@constCast(reply));

                    var it: ?*Packet = packet;
                    var event_offset: u32 = 0;
                    while (it) |batched| {
                        if (batched != packet) batched.assert_phase(.batched);
                        it = batched.batch_next;

                        const event_count = @divExact(
                            batched.data_size,
                            @sizeOf(StateMachine.EventType(operation_comptime)),
                        );
                        const batched_reply = demuxer.decode(event_offset, event_count);
                        event_offset += event_count;

                        if (!StateMachine.batch_logical_allowed.get(operation_comptime)) {
                            assert(batched.batch_next == null);
                            assert(batched_reply.len == reply.len);
                        }

                        assert(batched.operation == @intFromEnum(operation_comptime));
                        self.notify_completion(batched, .{
                            .timestamp = timestamp,
                            .reply = batched_reply,
                        });
                    }
                },
            }
        }

        fn notify_completion(
            self: *Context,
            packet: *Packet,
            completion: PacketError!struct {
                timestamp: u64,
                reply: []const u8,
            },
        ) void {
            const result = completion catch |err| {
                packet.status = switch (err) {
                    error.TooMuchData => .too_much_data,
                    error.ClientEvicted => .client_evicted,
                    error.ClientReleaseTooLow => .client_release_too_low,
                    error.ClientReleaseTooHigh => .client_release_too_high,
                    error.ClientShutdown => .client_shutdown,
                    error.InvalidOperation => .invalid_operation,
                    error.InvalidDataSize => .invalid_data_size,
                };
                assert(packet.status != .ok);
                packet.phase = .complete;

                // The packet completed with an error.
                (self.completion_callback)(
                    self.completion_context,
                    packet.cast(),
                    0,
                    null,
                    0,
                );
                return;
            };

            // The packet completed normally.
            assert(packet.status == .ok);
            packet.phase = .complete;
            (self.completion_callback)(
                self.completion_context,
                packet.cast(),
                result.timestamp,
                result.reply.ptr,
                @intCast(result.reply.len),
            );
        }

        // VTable functions called by `ClientInterface`, which are thread-safe.

        fn vtable_submit_fn(context: *anyopaque, packet_extern: *Packet.Extern) void {
            const self: *Context = @ptrCast(@alignCast(context));
            assert(self.signal.status() == .running);

            // Packet is caller-allocated to enable elastic intrusive-link-list-based
            // memory management. However, some of Packet's fields are essentially private.
            // Initialize them here to avoid threading default fields through FFI boundary.
            const packet: *Packet = packet_extern.cast();
            packet.* = .{
                .user_data = packet_extern.user_data,
                .operation = packet_extern.operation,
                .data_size = packet_extern.data_size,
                .data = packet_extern.data,
                .user_tag = packet_extern.user_tag,
                .status = .ok,
                .next = null,
                .batch_next = null,
                .batch_tail = null,
                .batch_size = 0,
                .batch_allowed = false,
                .phase = .submitted,
            };

            // Enqueue the packet and notify the IO thread to process it asynchronously.
            self.submitted.push(packet);
            self.signal.notify();
        }

        fn vtable_completion_context_fn(context: *anyopaque) usize {
            const self: *Context = @ptrCast(@alignCast(context));
            return self.completion_context;
        }

        fn vtable_deinit_fn(context: *anyopaque) void {
            const self: *Context = @ptrCast(@alignCast(context));
            assert(self.signal.status() == .running);

            self.signal.stop();
            self.thread.join();

            assert(self.submitted.pop() == null);
            assert(self.pending.pop() == null);

            self.io.cancel_all();

            self.signal.deinit();
            self.client.deinit(self.allocator);
            self.message_pool.deinit(self.allocator);
            self.io.deinit();

            self.allocator.destroy(self);
        }

        fn operation_from_int(op: u8) ?StateMachine.Operation {
            inline for (allowed_operations) |operation| {
                if (op == @intFromEnum(operation)) {
                    return operation;
                }
            }
            return null;
        }

        fn batch_logical_allowed(
            operation: StateMachine.Operation,
            data: ?*const anyopaque,
            data_size: u32,
        ) bool {
            if (!StateMachine.batch_logical_allowed.get(operation)) return false;

            // TODO(king): Remove this code once protocol batching is implemented.
            //
            // If the application submits an unclosed linked chain, it can inadvertently make
            // the elements of the next batch part of it.
            // To work around this issue, we don't allow unclosed linked chains to be batched.
            if (data_size > 0) {
                assert(data != null);
                const linked_chain_open: bool = switch (operation) {
                    inline .create_accounts,
                    .create_transfers,
                    => |tag| linked_chain_open: {
                        const Event = StateMachine.EventType(tag);
                        // Packet data isn't necessarily aligned.
                        const events: [*]align(@alignOf(u8)) const Event = @ptrCast(data.?);
                        const events_count: usize = @divExact(data_size, @sizeOf(Event));
                        break :linked_chain_open events[events_count - 1].flags.linked;
                    },
                    else => false,
                };

                if (linked_chain_open) return false;
            }

            return true;
        }

        test "client_batch_linked_chain" {
            inline for ([_]StateMachine.Operation{
                .create_accounts,
                .create_transfers,
            }) |operation| {
                const Event = StateMachine.EventType(operation);
                var data = [_]Event{std.mem.zeroInit(Event, .{})} ** 3;

                // Broken linked chain cannot be batched.
                for (&data) |*item| item.flags.linked = true;
                try std.testing.expect(!batch_logical_allowed(
                    operation,
                    data[0..],
                    data.len * @sizeOf(Event),
                ));

                // Valid linked chain.
                data[data.len - 1].flags.linked = false;
                try std.testing.expect(batch_logical_allowed(
                    operation,
                    data[0..],
                    data.len * @sizeOf(Event),
                ));

                // Single element.
                try std.testing.expect(batch_logical_allowed(
                    operation,
                    &data[data.len - 1],
                    1 * @sizeOf(Event),
                ));

                // No elements.
                try std.testing.expect(batch_logical_allowed(
                    operation,
                    null,
                    0,
                ));
            }
        }
    };
}

/// Implements the `Mutex` API as an `extern` struct, based on `std.Thread.Futex`.
/// Vendored from `std.Thread.Mutex.FutexImpl`.
const Locker = extern struct {
    const Futex = std.Thread.Futex;
    const unlocked: u32 = 0b00;
    const locked: u32 = 0b01;
    const contended: u32 = 0b11; // Must contain the `locked` bit for x86 optimization below.

    state: std.atomic.Value(u32) = std.atomic.Value(u32).init(unlocked),

    fn lock(self: *Locker) void {
        if (!self.try_lock()) {
            self.lock_slow();
        }
    }

    fn try_lock(self: *Locker) bool {
        // On x86, use `lock bts` instead of `lock cmpxchg` as:
        // - they both seem to mark the cache-line as modified regardless: https://stackoverflow.com/a/63350048.
        // - `lock bts` is smaller instruction-wise which makes it better for inlining.
        if (comptime builtin.target.cpu.arch.isX86()) {
            const locked_bit = @ctz(locked);
            return self.state.bitSet(locked_bit, .acquire) == 0;
        }

        // Acquire barrier ensures grabbing the lock happens before the critical section
        // and that the previous lock holder's critical section happens before we grab the lock.
        return self.state.cmpxchgWeak(unlocked, locked, .acquire, .monotonic) == null;
    }

    fn lock_slow(self: *Locker) void {
        @branchHint(.cold);

        // Avoid doing an atomic swap below if we already know the state is contended.
        // An atomic swap unconditionally stores which marks the cache-line as modified
        // unnecessarily.
        if (self.state.load(.monotonic) == contended) {
            Futex.wait(&self.state, contended);
        }

        // Try to acquire the lock while also telling the existing lock holder that there are
        // threads waiting.
        //
        // Once we sleep on the Futex, we must acquire the mutex using `contended` rather than
        // `locked`.
        // If not, threads sleeping on the Futex wouldn't see the state change in unlock and
        // potentially deadlock.
        // The downside is that the last mutex unlocker will see `contended` and do an unnecessary
        // Futex wake but this is better than having to wake all waiting threads on mutex unlock.
        //
        // Acquire barrier ensures grabbing the lock happens before the critical section
        // and that the previous lock holder's critical section happens before we grab the lock.
        while (self.state.swap(contended, .acquire) != unlocked) {
            Futex.wait(&self.state, contended);
        }
    }

    fn unlock(self: *Locker) void {
        // Unlock the mutex and wake up a waiting thread if any.
        //
        // A waiting thread will acquire with `contended` instead of `locked`
        // which ensures that it wakes up another thread on the next unlock().
        //
        // Release barrier ensures the critical section happens before we let go of the lock
        // and that our critical section happens before the next lock holder grabs the lock.
        const state = self.state.swap(unlocked, .release);
        assert(state != unlocked);

        if (state == contended) {
            Futex.wake(&self.state, 1);
        }
    }
};

const testing = std.testing;
test "Locker: smoke test" {
    var locker = Locker{};

    try testing.expect(locker.try_lock());
    try testing.expect(!locker.try_lock());
    locker.unlock();

    locker.lock();
    try testing.expect(!locker.try_lock());
    locker.unlock();
}

test "Locker: contended" {
    const threads_count = 4;
    const increments = 1000;

    const State = struct {
        locker: Locker = .{},
        counter: u32 = 0,
    };

    const Runner = struct {
        thread: std.Thread = undefined,
        state: *State,
        fn run(self: *@This()) void {
            while (true) {
                self.state.locker.lock();
                defer self.state.locker.unlock();
                if (self.state.counter == increments) break;
                self.state.counter += 1;
            }
        }
    };

    var state = State{};
    var runners: [threads_count]Runner = undefined;
    for (&runners) |*runner| {
        runner.* = .{ .state = &state };
        runner.thread = try std.Thread.spawn(.{}, Runner.run, .{runner});
    }
    for (&runners) |*runner| {
        runner.thread.join();
    }

    try testing.expectEqual(state.counter, increments);
}
