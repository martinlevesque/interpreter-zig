const std = @import("std");

const Token = struct {
    identifier: []const u8,
    char: u8,
};

pub fn tokenize(input: []const u8) std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);

    for (input) |char| {
        switch (char) {
            '(' => {
                tokens.append(Token{ .identifier = "LEFT_PAREN", .char = char }) catch unreachable;
            },
            ')' => {
                tokens.append(Token{ .identifier = "RIGHT_PAREN", .char = char }) catch unreachable;
            },
            '{' => {
                tokens.append(Token{ .identifier = "LEFT_BRACE", .char = char }) catch unreachable;
            },
            ',' => {
                tokens.append(Token{ .identifier = "COMMA", .char = char }) catch unreachable;
            },
            '.' => {
                tokens.append(Token{ .identifier = "DOT", .char = char }) catch unreachable;
            },
            '-' => {
                tokens.append(Token{ .identifier = "MINUS", .char = char }) catch unreachable;
            },
            '+' => {
                tokens.append(Token{ .identifier = "PLUS", .char = char }) catch unreachable;
            },
            ';' => {
                tokens.append(Token{ .identifier = "SEMICOLON", .char = char }) catch unreachable;
            },
            '*' => {
                tokens.append(Token{ .identifier = "STAR", .char = char }) catch unreachable;
            },
            else => {},
        }
    }

    tokens.append(Token{ .identifier = "EOF", .char = 0 }) catch unreachable;

    return tokens;
}
