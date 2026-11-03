// Course-supplied transport, using the same HTTP API as the Zig starter.
const std = @import("std");

pub const LSPClient = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    last_error: ?[]u8 = null,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, url: ?[]const u8) !LSPClient {
        return .{ .allocator = allocator, .io = io, .url = url orelse return error.MissingLSPTransport };
    }

    pub fn deinit(self: *LSPClient) void {
        if (self.last_error) |message| self.allocator.free(message);
        self.last_error = null;
    }

    // Borrowed helper error text, valid until the next call or deinit.
    pub fn lastError(self: LSPClient) ?[]const u8 {
        return self.last_error;
    }

    // The caller owns the returned JSON bytes and parses them with std.json.
    pub fn call(self: *LSPClient, action: []const u8, json: []const u8) ![]u8 {
        if (self.last_error) |message| self.allocator.free(message);
        self.last_error = null;
        const url = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ self.url, action });
        defer self.allocator.free(url);
        var client: std.http.Client = .{ .allocator = self.allocator, .io = self.io };
        defer client.deinit();
        var output: std.Io.Writer.Allocating = .init(self.allocator);
        defer output.deinit();
        const result = try client.fetch(.{
            .location = .{ .url = url }, .method = .POST, .payload = json,
            .extra_headers = &.{.{ .name = "content-type", .value = "application/json" }},
            .response_writer = &output.writer,
        });
        if (result.status != .ok) {
            self.last_error = try self.allocator.dupe(u8, output.written());
            return error.LSPTransportFailure;
        }
        return self.allocator.dupe(u8, output.written());
    }
};
