const std = @import("std");

const TokenizeError = error{LexicalError};

const Token = struct {
    identifier: []const u8,
    char: u8,
    lineNumber: u32 = 0,
    err: ?TokenizeError = null,
};

fn tokenAt(input: []const u8, index: usize, line: *u32) ?Token {
    if (index >= input.len) {
        return null;
    }

    const char = input[index];

    switch (char) {
        '(' => {
            return Token{ .identifier = "LEFT_PAREN", .char = char, .lineNumber = line.* };
        },
        ')' => {
            return Token{ .identifier = "RIGHT_PAREN", .char = char, .lineNumber = line.* };
        },
        '{' => {
            return Token{ .identifier = "LEFT_BRACE", .char = char, .lineNumber = line.* };
        },
        '}' => {
            return Token{ .identifier = "RIGHT_BRACE", .char = char, .lineNumber = line.* };
        },
        ',' => {
            return Token{ .identifier = "COMMA", .char = char, .lineNumber = line.* };
        },
        '.' => {
            return Token{ .identifier = "DOT", .char = char, .lineNumber = line.* };
        },
        '-' => {
            return Token{ .identifier = "MINUS", .char = char, .lineNumber = line.* };
        },
        '+' => {
            return Token{ .identifier = "PLUS", .char = char, .lineNumber = line.* };
        },
        ';' => {
            return Token{ .identifier = "SEMICOLON", .char = char, .lineNumber = line.* };
        },
        '*' => {
            return Token{ .identifier = "STAR", .char = char, .lineNumber = line.* };
        },
        '=' => {
            return Token{ .identifier = "EQUAL", .char = char, .lineNumber = line.* };
        },
        '\n' => {
            line.* = line.* + 1;
        },
        else => {
            return Token{ .identifier = "", .char = char, .lineNumber = line.*, .err = TokenizeError.LexicalError };
        },
    }

    return null;
}

pub fn tokenize(input: []const u8) std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
    var line: u32 = 1;
    var skipNext = false;

    for (input, 0..) |char, i| {
        if (skipNext) {
            skipNext = false;
            continue;
        }

        const currentToken = tokenAt(input, i, &line);
        const nextToken = tokenAt(input, i + 1, &line);

        if (currentToken) |token| {
            if (nextToken) |givenNextToken| {
                if (std.mem.eql(u8, givenNextToken.identifier, "EQUAL") and std.mem.eql(u8, token.identifier, "EQUAL")) {
                    tokens.append(Token{ .identifier = "EQUAL_EQUAL", .char = char, .lineNumber = line }) catch unreachable;

                    skipNext = true;
                    continue;
                }
            }

            tokens.append(token) catch unreachable;
        }
    }

    tokens.append(Token{ .identifier = "EOF", .char = 0 }) catch unreachable;

    return tokens;
}
