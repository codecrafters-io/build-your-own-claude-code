const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var arg_it = try std.process.Args.Iterator.initAllocator(init.minimal.args, allocator);
    defer arg_it.deinit();

    _ = arg_it.next(); // argv0
    const flag = arg_it.next() orelse @panic("Usage: main -p <prompt>");
    const prompt_str = arg_it.next() orelse @panic("Usage: main -p <prompt>");
    if (!std.mem.eql(u8, flag, "-p")) {
        @panic("Usage: main -p <prompt>");
    }

    // CodeCrafters sets OPENROUTER_API_KEY and OPENROUTER_BASE_URL when it runs your tests.
    // To run your program locally, set OPENROUTER_API_KEY to your own OpenRouter key.
    const api_key = init.environ_map.get("OPENROUTER_API_KEY") orelse @panic("OPENROUTER_API_KEY is not set. CodeCrafters sets it when you run `codecrafters test` or `codecrafters submit`. To run your program directly, set it to your own OpenRouter key.");
    const base_url = init.environ_map.get("OPENROUTER_BASE_URL") orelse "https://openrouter.ai/api/v1";

    // CodeCrafters sets OPENROUTER_MODEL to anthropic/claude-haiku-4.5 when it runs your tests. Locally, you can set it to any model.
    const model = init.environ_map.get("OPENROUTER_MODEL") orelse "anthropic/claude-haiku-4.5";

    // Build request body
    var body_out: std.Io.Writer.Allocating = .init(allocator);
    defer body_out.deinit();
    var jw: std.json.Stringify = .{ .writer = &body_out.writer };
    try jw.write(.{
        .model = model,
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
    var client: std.http.Client = .{
        .allocator = allocator,
        .io = io,
    };
    defer client.deinit();

    var response_out: std.Io.Writer.Allocating = .init(allocator);
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

    // You can use print statements as follows for debugging, they'll be visible when running tests.
    std.debug.print("Logs from your program will appear here!\n", .{});

    // TODO: Uncomment the lines below to pass the first stage
    // const content = choices.array.items[0].object.get("message").?.object.get("content").?.string;
    // try std.Io.File.stdout().writeStreamingAll(io, content);
}
