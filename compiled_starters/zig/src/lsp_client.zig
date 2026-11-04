// Course-supplied transport, using the same HTTP API as the Zig starter.
const std = @import("std");

pub const LSPClient = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    last_error: ?[]u8 = null,
    configuration: ?std.json.Parsed(std.json.Value) = null,
    extension_to_language: std.json.ObjectMap = undefined,

    pub fn fromEnvironment(allocator: std.mem.Allocator, io: std.Io, environ: *const std.process.Environ.Map) !?LSPClient {
        const url = environ.get("CODECRAFTERS_LSP_URL") orelse return null;
        return try init(allocator, io, url);
    }

    pub fn init(allocator: std.mem.Allocator, io: std.Io, url: ?[]const u8) !LSPClient {
        var client: LSPClient = .{
            .allocator = allocator,
            .io = io,
            .url = url orelse return error.MissingLSPTransport,
        };
        errdefer client.deinit();
        const json = try client.call("configuration", "{}");
        defer allocator.free(json);
        client.configuration = try std.json.parseFromSlice(std.json.Value, allocator, json, .{ .allocate = .alloc_always });
        const mapping = client.configuration.?.value.object.get("extensionToLanguage") orelse return error.MissingLanguageMapping;
        client.extension_to_language = mapping.object;
        return client;
    }

    pub fn deinit(self: *LSPClient) void {
        if (self.configuration) |configuration| configuration.deinit();
        self.configuration = null;
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
            .location = .{ .url = url },
            .method = .POST,
            .payload = json,
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
