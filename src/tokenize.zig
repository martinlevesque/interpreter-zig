const std = @import("std");

const TokenizeError = error{LexicalError};

pub const TokenType = enum {
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACE,
    RIGHT_BRACE,
    LESS,
    LESS_EQUAL,
    GREATER,
    GREATER_EQUAL,
    SLASH,
    SLASH_SLASH,
    COMMA,
    DOT,
    MINUS,
    PLUS,
    SEMICOLON,
    STAR,
    EQUAL,
    BANG_EQUAL,
    EQUAL_EQUAL,
    BANG,
    SPACE,
    TAB,
    INVALID,
    NONE,
    EOF,
};

const Token = struct {
    type: TokenType,
    lexeme: []const u8,
    literalStr: []const u8 = "",
    inputChar: u8 = 0,
    lineNumber: u32 = 0,
    err: ?TokenizeError = null,
};

const AdvanceResult = struct {
    position: usize,
    result: ?Token,
};

const LexemeSetup = struct {
    currentType: TokenType,
    nextType: TokenType,
    thenType: TokenType,
    thenLexeme: []const u8,
    skipUpTo: u8 = 0,
    includeToken: bool = true,
    skipOnCurrent: bool = false,
    advance: *const fn ([]const u8, usize) ?AdvanceResult,
};

fn tokenAt(input: []const u8, index: usize, line: u32) !?Token {
    if (index >= input.len) {
        return null;
    }

    const char = input[index];

    switch (char) {
        '(' => {
            return Token{ .type = TokenType.LEFT_PAREN, .lexeme = "(", .lineNumber = line };
        },
        ')' => {
            return Token{ .type = TokenType.RIGHT_PAREN, .lexeme = ")", .lineNumber = line };
        },
        '{' => {
            return Token{ .type = TokenType.LEFT_BRACE, .lexeme = "{", .lineNumber = line };
        },
        '}' => {
            return Token{ .type = TokenType.RIGHT_BRACE, .lexeme = "}", .lineNumber = line };
        },
        '<' => {
            return Token{ .type = TokenType.LESS, .lexeme = "<", .lineNumber = line };
        },
        '>' => {
            return Token{ .type = TokenType.GREATER, .lexeme = ">", .lineNumber = line };
        },
        '/' => {
            return Token{ .type = TokenType.SLASH, .lexeme = "/", .lineNumber = line };
        },
        ',' => {
            return Token{ .type = TokenType.COMMA, .lexeme = ",", .lineNumber = line };
        },
        '.' => {
            return Token{ .type = TokenType.DOT, .lexeme = ".", .lineNumber = line };
        },
        '-' => {
            return Token{ .type = TokenType.MINUS, .lexeme = "-", .lineNumber = line };
        },
        '+' => {
            return Token{ .type = TokenType.PLUS, .lexeme = "+", .lineNumber = line };
        },
        ';' => {
            return Token{ .type = TokenType.SEMICOLON, .lexeme = ";", .lineNumber = line };
        },
        '*' => {
            return Token{ .type = TokenType.STAR, .lexeme = "*", .lineNumber = line };
        },
        '=' => {
            return Token{ .type = TokenType.EQUAL, .lexeme = "=", .lineNumber = line };
        },
        '!' => {
            return Token{ .type = TokenType.BANG, .lexeme = "!", .lineNumber = line };
        },
        ' ' => {
            return Token{ .type = TokenType.SPACE, .lexeme = " ", .lineNumber = line };
        },
        '\t' => {
            return Token{ .type = TokenType.TAB, .lexeme = "\t", .lineNumber = line };
        },
        '\n' => {},
        else => {
            return Token{ .type = TokenType.INVALID, .lexeme = "", .inputChar = char, .lineNumber = line, .err = TokenizeError.LexicalError };
        },
    }

    return null;
}

fn charAtIndex(input: []const u8, i: usize, char: u8) ?usize {
    if (i < input.len and input[i] == char) {
        return i;
    }

    return null;
}

fn structCharAt(char: u8) type {
    return struct {
        fn f(input: []const u8, i: usize) ?usize {
            return charAtIndex(input, i + 1, char);
        }
        const ptr = f; // Assign function pointer
    };
}

fn structAdvanceFindNext(token: Token, char: u8) type {
    return struct {
        fn f(line: usize, input: []const u8, i: usize) ?Token {
            for (i..input.len) |idx| {
                if (input[idx] == char) {
                    return Token{
                        .type = token.type,
                        .lexeme = token.lexeme,
                        .inputChar = token.inputChar,
                        .lineNumber = line,
                    };
                }
            }
            return null;
        }
        const ptr = f;
    };
}

fn structAdvanceOne(token: Token, char: u8) type {
    return struct {
        fn f(line: usize, _: []const u8, i: usize) ?Token { // todo ret pair
            return Token{
                .type = token.type,
                .lexeme = token.lexeme,
                .inputChar = token.inputChar,
                .lineNumber = line,
            };
        }
        const ptr = f;
    };
}

fn setupMultiTokensLexemes() !std.ArrayList(LexemeSetup) {
    var lexemes = std.ArrayList(LexemeSetup).init(std.heap.page_allocator);

    try lexemes.append(LexemeSetup{
        .currentType = TokenType.EQUAL,
        .nextType = TokenType.EQUAL,
        .thenType = TokenType.EQUAL_EQUAL,
        .thenLexeme = "==",
        .skipUpTo = '=',
        .advance = structAdvanceFindNext(Token{ .type = TokenType.EQUAL_EQUAL, .inputChar = '=', .lexeme = "==" }, '=').ptr,
    });
    try lexemes.append(LexemeSetup{
        .currentType = TokenType.BANG,
        .nextType = TokenType.EQUAL,
        .thenType = TokenType.BANG_EQUAL,
        .thenLexeme = "!=",
        .advance = structAdvanceFindNext(Token{ .type = TokenType.BANG_EQUAL, .inputChar = '!', .lexeme = "!=" }, '=').ptr,
    });
    try lexemes.append(LexemeSetup{
        .currentType = TokenType.LESS,
        .nextType = TokenType.EQUAL,
        .thenType = TokenType.LESS_EQUAL,
        .thenLexeme = "<=",
        .advance = structAdvanceFindNext(Token{ .type = TokenType.LESS_EQUAL, .inputChar = '<', .lexeme = "<=" }, '=').ptr,
    });
    try lexemes.append(LexemeSetup{
        .currentType = TokenType.GREATER,
        .nextType = TokenType.EQUAL,
        .thenType = TokenType.GREATER_EQUAL,
        .thenLexeme = ">=",
        .advance = structAdvanceFindNext(Token{ .type = TokenType.GREATER_EQUAL, .inputChar = '>', .lexeme = ">=" }, '=').ptr,
    });
    try lexemes.append(LexemeSetup{
        .currentType = TokenType.SLASH,
        .nextType = TokenType.SLASH,
        .thenType = TokenType.SLASH_SLASH,
        .thenLexeme = "//",
        .includeToken = false,
        .advance = structAdvanceFindNext(Token{ .type = TokenType.SLASH_SLASH, .inputChar = '/', .lexeme = "//" }, '\n').ptr,
    });
    try lexemes.append(LexemeSetup{
        .currentType = TokenType.SPACE,
        .nextType = TokenType.NONE,
        .thenType = TokenType.NONE,
        .thenLexeme = "",
        .includeToken = false,
        .skipOnCurrent = true,
        .advance = structAdvanceOne(Token{ .type = TokenType.NONE, .inputChar = ' ', .lexeme = "" }, ' ').ptr,
    });

    try lexemes.append(LexemeSetup{
        .currentType = TokenType.TAB,
        .nextType = TokenType.NONE,
        .thenType = TokenType.NONE,
        .thenLexeme = "",
        .includeToken = false,
        .skipOnCurrent = true,
    });

    return lexemes;
}

pub fn tokenize(input: []const u8) !std.ArrayList(Token) {
    var tokens = std.ArrayList(Token).init(std.heap.page_allocator);
    var line: u32 = 1;
    var skipUpTo: u8 = 0;
    const setupLexemes: std.ArrayList(LexemeSetup) = try setupMultiTokensLexemes();
    defer setupLexemes.deinit();
    var i: usize = 0;

    while (i < input.len) {
        const char = input[i];

        if (char == '\n') {
            line = line + 1;
        }

        const currentToken = try tokenAt(input, i, line);
        const nextToken = try tokenAt(input, i + 1, line);

        if (currentToken) |token| {
            var shouldAddToken = true;

            for (setupLexemes.items) |lexeme| {
                if (token.type == lexeme.currentType and lexeme.skipOnCurrent) {
                    // if it's this given identifier, skip
                    shouldAddToken = false;
                    break;
                }
            }

            if (nextToken) |givenNextToken| {
                var foundSetupLexeme = false;

                for (setupLexemes.items) |lexeme| {
                    if (givenNextToken.type == lexeme.nextType and token.type == lexeme.currentType) {
                        if (lexeme.includeToken) {
                            try tokens.append(Token{ .type = lexeme.thenType, .lexeme = lexeme.thenLexeme, .lineNumber = line });
                        }

                        foundSetupLexeme = true;
                        skipUpTo = lexeme.skipUpTo;
                        break;
                    }
                }

                if (foundSetupLexeme) {
                    // we found a multi tokens lexeme valid
                    i = i + 1;
                    continue;
                }
            }

            if (shouldAddToken) {
                try tokens.append(token);
            }
        }

        i = i + 1;
    }

    try tokens.append(Token{ .type = TokenType.EOF, .lexeme = "EOF" });

    return tokens;
}
