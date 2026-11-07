// Only needed for the LSP extension.
// You can ignore this file until you reach that extension.
// Course-supplied client for the language server the tester starts. It uses the same HTTP API as the Zig starter.
const std = @import("std");

/// Sends your agent's messages to the language server.
///
/// The client doesn't track open documents or versions; that state belongs in
/// your agent. Payloads and responses are JSON text; parse responses with
/// std.json.
///
/// Example:
///
///     var lsp = try LSPClient.fromEnvironment(allocator, io, init.environ_map);
///     defer if (lsp) |*client| client.deinit();
///     if (lsp) |*client| {
///         const language = client.extension_to_language.get(".py"); // "python"
///         const result = try client.call("request", request_json);
///         defer allocator.free(result);
///     }
pub const LSPClient = struct {
    allocator: std.mem.Allocator,
    io: std.Io,
    url: []const u8,
    last_error: ?[]u8 = null,
    configuration: ?std.json.Parsed(std.json.Value) = null,
    /// Maps file extensions, including the dot, to LSP language IDs, such as
    /// {".py": "python"}. Owned by the client and valid until deinit.
    extension_to_language: std.json.ObjectMap = undefined,

    /// Connects to the language server the tester configured. Returns null
    /// when no language server is configured. Call deinit when done.
    pub fn fromEnvironment(allocator: std.mem.Allocator, io: std.Io, environ: *const std.process.Environ.Map) !?LSPClient {
        const url = environ.get("CODECRAFTERS_LSP_URL") orelse return null;
        return try init(allocator, io, url);
    }

    /// Connects to the transport at url and reads the extension-to-language
    /// mapping. Call deinit when done.
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

    /// Frees the language mapping and any saved error text.
    pub fn deinit(self: *LSPClient) void {
        if (self.configuration) |configuration| configuration.deinit();
        self.configuration = null;
        if (self.last_error) |message| self.allocator.free(message);
        self.last_error = null;
    }

    /// The transport's error text after call returned error.LSPTransportFailure,
    /// or null. Borrowed: valid until the next call or deinit.
    pub fn lastError(self: LSPClient) ?[]const u8 {
        return self.last_error;
    }

    /// Sends one action to the language server.
    ///
    /// Actions and their payloads:
    ///
    ///   - "configuration": {}. Returns {"extensionToLanguage": {".py": "python"}}.
    ///   - "notify": {"method": ..., "params": {...}}, an LSP notification.
    ///     Returns null.
    ///   - "request": {"method": ..., "params": {...}}, an LSP request. Returns the
    ///     server's result, which may be null, an object, or an array.
    ///   - "notifications": {"after": cursor, "timeoutMs": ms}. Returns
    ///     {"cursor": n, "notifications": [...]}: the server's notifications after
    ///     the cursor, each with "method" and "params". Waits up to ms (0 to 5000)
    ///     when none are queued yet. Pass the returned cursor as "after" next time.
    ///
    /// Returns the response as JSON bytes. The caller owns them and frees them
    /// with the client's allocator.
    ///
    /// Returns error.LSPTransportFailure when the language server returns an
    /// error, times out (5 seconds for a request), or exits. lastError() then
    /// holds the transport's JSON, such as {"error":"language server exited before responding to textDocument/definition"}.
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
