const std = @import("std");
const tokenize = @import("tokenize.zig");

pub fn main() !void {
    std.debug.print("Starting interpreter\n", .{});

    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 3) {
        std.debug.print("Usage: ./your_program.sh tokenize <filename>\n", .{});
        std.process.exit(1);
    }

    const command = args[1];
    const filename = args[2];

    if (!std.mem.eql(u8, command, "tokenize")) {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.process.exit(1);
    }

    const file_contents = try std.fs.cwd().readFileAlloc(std.heap.page_allocator, filename, std.math.maxInt(usize));
    defer std.heap.page_allocator.free(file_contents);

    if (file_contents.len > 0) {
        const tokens = tokenize.tokenize(file_contents);
        defer tokens.deinit();

        for (tokens.items) |token| {
            if (token.char == 0) {
                try stdout.print("{s}  null\n", .{token.identifier});
            } else {
                try stdout.print("{s} {c} null\n", .{ token.identifier, token.char });
            }
        }
    } else {
        try std.io.getStdOut().writer().print("EOF  null\n", .{}); // Placeholder, remove this line when implementing the scanner
    }
}
