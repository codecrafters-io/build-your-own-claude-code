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
    var body_buf = std.ArrayList(u8).init(allocator);
    defer body_buf.deinit();
    const bw = body_buf.writer();
    try bw.writeAll("{\"model\":\"anthropic/claude-haiku-4.5\",\"messages\":[{\"role\":\"user\",\"content\":");
    try std.json.stringify(prompt.?, .{}, bw);
    try bw.writeAll("}]}");

    // Build URL and auth header
    const url = try std.fmt.allocPrint(allocator, "{s}/chat/completions", .{base_url});
    defer allocator.free(url);

    const auth_header = try std.fmt.allocPrint(allocator, "Bearer {s}", .{api_key});
    defer allocator.free(auth_header);

    // Make HTTP POST request
    var client: std.http.Client = .{ .allocator = allocator };
    defer client.deinit();

    var response_body = std.ArrayList(u8).init(allocator);
    defer response_body.deinit();

    var server_header_buffer: [16 * 1024]u8 = undefined;
    const result = try client.fetch(.{
        .location = .{ .url = url },
        .method = .POST,
        .payload = body_buf.items,
        .extra_headers = &.{
            .{ .name = "Authorization", .value = auth_header },
            .{ .name = "Content-Type", .value = "application/json" },
        },
        .response_storage = .{ .dynamic = &response_body },
        .server_header_buffer = &server_header_buffer,
    });
    _ = result;

    // Parse JSON response
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, response_body.items, .{});
    defer parsed.deinit();

    const choices = parsed.value.object.get("choices") orelse
        @panic("No choices in response");
    if (choices.array.items.len == 0)
        @panic("No choices in response");

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    std.debug.print("Logs from your program will appear here!\n", .{});

    // TODO: Uncomment the lines below to pass the first stage
    // const content = choices.array.items[0].object.get("message").?.object.get("content").?.string;
    // const stdout = std.io.getStdOut().writer();
    // try stdout.writeAll(content);
}
