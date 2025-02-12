const std = @import("std");

const TokenizeError = error{LexicalError};

const Token = struct {
    identifier: []const u8,
    lexeme: []const u8,
    inputChar: u8 = 0,
    lineNumber: u32 = 0,
    err: ?TokenizeError = null,
};

const LexemeSetup = struct {
    currentIdentifier: []const u8,
    nextIdentifier: []const u8,
    thenIdentifier: []const u8,
    thenLexeme: []const u8,
    skipUpTo: u8,
    includeToken: bool = true,
};

fn tokenAt(input: []const u8, index: usize, line: u32) !?Token {
    if (index >= input.len) {
        return null;
    }

    const char = input[index];

    switch (char) {
        '(' => {
            return Token{ .identifier = "LEFT_PAREN", .lexeme = "(", .lineNumber = line };
        },
        ')' => {
            return Token{ .identifier = "RIGHT_PAREN", .lexeme = ")", .lineNumber = line };
        },
        '{' => {
            return Token{ .identifier = "LEFT_BRACE", .lexeme = "{", .lineNumber = line };
        },
        '}' => {
            return Token{ .identifier = "RIGHT_BRACE", .lexeme = "}", .lineNumber = line };
        },
        '<' => {
            return Token{ .identifier = "LESS", .lexeme = "<", .lineNumber = line };
        },
        '>' => {
            return Token{ .identifier = "GREATER", .lexeme = ">", .lineNumber = line };
        },
        '/' => {
            return Token{ .identifier = "SLASH", .lexeme = "/", .lineNumber = line };
        },
        ',' => {
            return Token{ .identifier = "COMMA", .lexeme = ",", .lineNumber = line };
        },
        '.' => {
            return Token{ .identifier = "DOT", .lexeme = ".", .lineNumber = line };
        },
        '-' => {
            return Token{ .identifier = "MINUS", .lexeme = "-", .lineNumber = line };
        },
        '+' => {
            return Token{ .identifier = "PLUS", .lexeme = "+", .lineNumber = line };
        },
        ';' => {
            return Token{ .identifier = "SEMICOLON", .lexeme = ";", .lineNumber = line };
        },
        '*' => {
            return Token{ .identifier = "STAR", .lexeme = "*", .lineNumber = line };
        },
        '=' => {
            return Token{ .identifier = "EQUAL", .lexeme = "=", .lineNumber = line };
        },
        '!' => {
            return Token{ .identifier = "BANG", .lexeme = "!", .lineNumber = line };
        },
        '\n' => {},
        else => {
            return Token{ .identifier = "", .lexeme = "", .inputChar = char, .lineNumber = line, .err = TokenizeError.LexicalError };
        },
    }

    return null;
}

fn setupMultiTokensLexemes() !std.ArrayList(LexemeSetup) {
    var lexemes = std.ArrayList(LexemeSetup).init(std.heap.page_allocator);

    try lexemes.append(LexemeSetup{
        .currentIdentifier = "EQUAL",
        .nextIdentifier = "EQUAL",
        .thenIdentifier = "EQUAL_EQUAL",
        .thenLexeme = "==",
        .skipUpTo = '=',
    });
    try lexemes.append(LexemeSetup{
        .currentIdentifier = "BANG",
        .nextIdentifier = "EQUAL",
        .thenIdentifier = "BANG_EQUAL",
        .thenLexeme = "!=",
        .skipUpTo = '=',
    });
    try lexemes.append(LexemeSetup{
        .currentIdentifier = "LESS",
        .nextIdentifier = "EQUAL",
        .thenIdentifier = "LESS_EQUAL",
        .thenLexeme = "<=",
        .skipUpTo = '=',
    });
    try lexemes.append(LexemeSetup{
        .currentIdentifier = "GREATER",
        .nextIdentifier = "EQUAL",
        .thenIdentifier = "GREATER_EQUAL",
        .thenLexeme = ">=",
        .skipUpTo = '=',
    });
    try lexemes.append(LexemeSetup{
        .currentIdentifier = "SLASH",
        .nextIdentifier = "SLASH",
        .thenIdentifier = "SLASH_SLASH",
        .thenLexeme = "//",
        .skipUpTo = '\n',
        .includeToken = false,
    });

    return lexemes;
}

pub fn tokenize(input: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
    var line: u32 = 1;
    var skipUpTo: u8 = 0;
    const setupLexemes: std.ArrayList(LexemeSetup) = try setupMultiTokensLexemes();
    defer setupLexemes.deinit();

    for (input, 0..) |char, i| {
        if (skipUpTo != 0 and skipUpTo != char) {
            continue;
        }

        if (char == '\n') {
            line = line + 1;
        }

        if (char == skipUpTo) {
            skipUpTo = 0;
            continue;
        }

        const currentToken = try tokenAt(input, i, line);
        const nextToken = try tokenAt(input, i + 1, line);

        if (currentToken) |token| {
            if (nextToken) |givenNextToken| {
                var foundSetupLexeme = false;

                for (setupLexemes.items) |lexeme| {
                    if (std.mem.eql(u8, givenNextToken.identifier, lexeme.nextIdentifier) and std.mem.eql(u8, token.identifier, lexeme.currentIdentifier)) {
                        if (lexeme.includeToken) {
                            try tokens.append(Token{ .identifier = lexeme.thenIdentifier, .lexeme = lexeme.thenLexeme, .lineNumber = line });
                        }

                        foundSetupLexeme = true;
                        skipUpTo = lexeme.skipUpTo;
                        break;
                    }
                }

                if (foundSetupLexeme) {
                    // we found a multi tokens lexeme valid
                    continue;
                }
            }

            try tokens.append(token);
        }
    }

    try tokens.append(Token{ .identifier = "EOF", .lexeme = "EOF" });

    return tokens;
}
