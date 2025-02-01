const std = @import("std");

const TokenizeError = error{LexicalError};

const Token = struct {
    identifier: []const u8,
    char: u8,
    lineNumber: u32 = 0,
    err: ?TokenizeError = null,
};

pub fn tokenize(input: []const u8) std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
    var line: u32 = 1;

    for (input) |char| {
        switch (char) {
            '(' => {
                tokens.append(Token{ .identifier = "LEFT_PAREN", .char = char, .lineNumber = line }) catch unreachable;
            },
            ')' => {
                tokens.append(Token{ .identifier = "RIGHT_PAREN", .char = char, .lineNumber = line }) catch unreachable;
            },
            '{' => {
                tokens.append(Token{ .identifier = "LEFT_BRACE", .char = char, .lineNumber = line }) catch unreachable;
            },
            '}' => {
                tokens.append(Token{ .identifier = "RIGHT_BRACE", .char = char, .lineNumber = line }) catch unreachable;
            },
            ',' => {
                tokens.append(Token{ .identifier = "COMMA", .char = char, .lineNumber = line }) catch unreachable;
            },
            '.' => {
                tokens.append(Token{ .identifier = "DOT", .char = char, .lineNumber = line }) catch unreachable;
            },
            '-' => {
                tokens.append(Token{ .identifier = "MINUS", .char = char, .lineNumber = line }) catch unreachable;
            },
            '+' => {
                tokens.append(Token{ .identifier = "PLUS", .char = char, .lineNumber = line }) catch unreachable;
            },
            ';' => {
                tokens.append(Token{ .identifier = "SEMICOLON", .char = char, .lineNumber = line }) catch unreachable;
            },
            '*' => {
                tokens.append(Token{ .identifier = "STAR", .char = char, .lineNumber = line }) catch unreachable;
            },
            '\n' => {
                line = line + 1;
            },
            else => {
                tokens.append(Token{ .identifier = "", .char = char, .lineNumber = line, .err = TokenizeError.LexicalError }) catch unreachable;
            },
        }
    }

    tokens.append(Token{ .identifier = "EOF", .char = 0 }) catch unreachable;

    return tokens;
}
