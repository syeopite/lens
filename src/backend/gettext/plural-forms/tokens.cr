module PluralForm
  extend self

  # All possible token types
  private enum TokenTypes
    LEFT_PAREN
    RIGHT_PAREN
    STAR
    SLASH
    MOD
    PLUS
    MINUS
    LESS
    LESS_EQUAL
    COLON
    SEMICOLON
    QUESTION

    AND
    OR
    NOT

    GREATER
    GREATER_EQUAL
    EQUAL
    EQUAL_EQUAL
    NOT_EQUAL

    IDENTIFIER
    NUMBER
  end

  # Object representing a token from the grammar of gettext po files
  private struct Token
    def initialize(@token_type : TokenTypes, @literal : String?, @column : Int32)
    end
  end
end
