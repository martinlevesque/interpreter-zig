const std = @import("std");

const TokenizeError = error{LexicalError};

const Token = struct {
    identifier: []const u8,
    lexeme: []const u8,
    inputChar: u8 = 0,
    lineNumber: u32 = 0,
    err: ?TokenizeError = null,
};

fn tokenAt(input: []const u8, index: usize, line: *u32) !?Token {
    if (index >= input.len) {
        return null;
    }

    const char = input[index];

    switch (char) {
        '(' => {
            return Token{ .identifier = "LEFT_PAREN", .lexeme = "(", .lineNumber = line.* };
        },
        ')' => {
            return Token{ .identifier = "RIGHT_PAREN", .lexeme = ")", .lineNumber = line.* };
        },
        '{' => {
            return Token{ .identifier = "LEFT_BRACE", .lexeme = "{", .lineNumber = line.* };
        },
        '}' => {
            return Token{ .identifier = "RIGHT_BRACE", .lexeme = "}", .lineNumber = line.* };
        },
        ',' => {
            return Token{ .identifier = "COMMA", .lexeme = ",", .lineNumber = line.* };
        },
        '.' => {
            return Token{ .identifier = "DOT", .lexeme = ".", .lineNumber = line.* };
        },
        '-' => {
            return Token{ .identifier = "MINUS", .lexeme = "-", .lineNumber = line.* };
        },
        '+' => {
            return Token{ .identifier = "PLUS", .lexeme = "+", .lineNumber = line.* };
        },
        ';' => {
            return Token{ .identifier = "SEMICOLON", .lexeme = ";", .lineNumber = line.* };
        },
        '*' => {
            return Token{ .identifier = "STAR", .lexeme = "*", .lineNumber = line.* };
        },
        '=' => {
            return Token{ .identifier = "EQUAL", .lexeme = "=", .lineNumber = line.* };
        },
        '\n' => {
            line.* = line.* + 1;
        },
        else => {
            return Token{ .identifier = "", .lexeme = "", .inputChar = char, .lineNumber = line.*, .err = TokenizeError.LexicalError };
        },
    }

    return null;
}

pub fn tokenize(input: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
    var line: u32 = 1;
    var skipNext = false;

    for (input, 0..) |_, i| {
        if (skipNext) {
            skipNext = false;
            continue;
        }

        const currentToken = try tokenAt(input, i, &line);
        const nextToken = try tokenAt(input, i + 1, &line);

        if (currentToken) |token| {
            if (nextToken) |givenNextToken| {
                if (std.mem.eql(u8, givenNextToken.identifier, "EQUAL") and std.mem.eql(u8, token.identifier, "EQUAL")) {
                    tokens.append(Token{ .identifier = "EQUAL_EQUAL", .lexeme = "==", .lineNumber = line }) catch unreachable;

                    skipNext = true;
                    continue;
                }
            }

            tokens.append(token) catch unreachable;
        }
    }

    tokens.append(Token{ .identifier = "EOF", .lexeme = "EOF" }) catch unreachable;

    return tokens;
}
