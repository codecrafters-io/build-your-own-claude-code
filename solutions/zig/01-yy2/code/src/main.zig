const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse -p flag
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var prompt: ?[]const u8 = null;
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        if (std.mem.eql(u8, args[i], "-p") and i + 1 < args.len) {
            i += 1;
            prompt = args[i];
        }
    }

    const prompt_str = prompt orelse @panic("Prompt must not be empty");

    const api_key = std.posix.getenv("OPENROUTER_API_KEY") orelse @panic("OPENROUTER_API_KEY is not set");
    const base_url = std.posix.getenv("OPENROUTER_BASE_URL") orelse "https://openrouter.ai/api/v1";

    // Build request body
    var body_out: std.io.Writer.Allocating = .init(allocator);
    defer body_out.deinit();
    var jw: std.json.Stringify = .{ .writer = &body_out.writer };
    try jw.write(.{
        .model = "anthropic/claude-haiku-4.5",
        .messages = &[_]struct { role: []const u8, content: []const u8 }{
            .{ .role = "user", .content = prompt_str },
        },
    });
    const body = body_out.written();

    // Build URL and auth header
    const url_str = try std.fmt.allocPrint(allocator, "{s}/chat/completions", .{base_url});
    defer allocator.free(url_str);

    const auth_value = try std.fmt.allocPrint(allocator, "Bearer {s}", .{api_key});
    defer allocator.free(auth_value);

    // Make HTTP request
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var response_out: std.io.Writer.Allocating = .init(allocator);
    defer response_out.deinit();

    _ = try client.fetch(.{
        .location = .{ .url = url_str },
        .method = .POST,
        .payload = body,
        .extra_headers = &.{
            .{ .name = "content-type", .value = "application/json" },
            .{ .name = "authorization", .value = auth_value },
        },
        .response_writer = &response_out.writer,
    });
    const response_body = response_out.written();

    // Parse response
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, response_body, .{});
    defer parsed.deinit();

    const choices = parsed.value.object.get("choices") orelse @panic("No choices in response");
    if (choices.array.items.len == 0) {
        @panic("No choices in response");
    }

    const content = choices.array.items[0].object.get("message").?.object.get("content").?.string;
    try std.fs.File.stdout().writeAll(content);
}
