const std = @import("std");

pub fn main() !void {
    var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();
    _ = args.next(); // skip program name

    var prompt: ?[]const u8 = null;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-p")) {
            prompt = args.next();
        }
    }

    if (prompt == null) {
        @panic("Prompt must not be empty");
    }

    const api_key = std.posix.getenv("OPENROUTER_API_KEY") orelse
        @panic("OPENROUTER_API_KEY is not set");

    const base_url = std.posix.getenv("OPENROUTER_BASE_URL") orelse
        "https://openrouter.ai/api/v1";

    // Build JSON request body
    const escaped_prompt = try jsonEncodeString(allocator, prompt.?);
    defer allocator.free(escaped_prompt);

    const body = try std.fmt.allocPrint(allocator, "{{\"model\":\"anthropic/claude-haiku-4.5\",\"messages\":[{{\"role\":\"user\",\"content\":{s}}}]}}", .{escaped_prompt});
    defer allocator.free(body);

    // Build URL and auth header
    const url = try std.fmt.allocPrint(allocator, "{s}/chat/completions", .{base_url});
    defer allocator.free(url);

    const auth_header = try std.fmt.allocPrint(allocator, "Bearer {s}", .{api_key});
    defer allocator.free(auth_header);

    // Make HTTP POST request
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();

    const result = try client.fetch(.{
        .location = .{ .url = url },
        .method = .POST,
        .payload = body,
        .extra_headers = &.{
            .{ .name = "Authorization", .value = auth_header },
            .{ .name = "Content-Type", .value = "application/json" },
        },
        .response_writer = &aw.writer,
    });
    _ = result;

    // Get response body
    const resp_body = aw.writer.buffer[0..aw.writer.end];

    // Parse JSON response
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, resp_body, .{});
    defer parsed.deinit();

    const choices = parsed.value.object.get("choices") orelse
        @panic("No choices in response");
    if (choices.array.items.len == 0)
        @panic("No choices in response");

    const content = choices.array.items[0].object.get("message").?.object.get("content").?.string;
    try std.io.getStdOut().writeAll(content);
}

fn jsonEncodeString(allocator: std.mem.Allocator, s: []const u8) ![]u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(allocator);

    try buf.append(allocator, '"');
    for (s) |c| {
        switch (c) {
            '"' => try buf.appendSlice(allocator, "\\\""),
            '\\' => try buf.appendSlice(allocator, "\\\\"),
            '\n' => try buf.appendSlice(allocator, "\\n"),
            '\r' => try buf.appendSlice(allocator, "\\r"),
            '\t' => try buf.appendSlice(allocator, "\\t"),
            else => {
                if (c < 0x20) {
                    var tmp: [6]u8 = undefined;
                    const escaped = std.fmt.bufPrint(&tmp, "\\u{x:0>4}", .{c}) catch unreachable;
                    try buf.appendSlice(allocator, escaped);
                } else {
                    try buf.append(allocator, c);
                }
            },
        }
    }
    try buf.append(allocator, '"');

    return buf.toOwnedSlice(allocator);
}
