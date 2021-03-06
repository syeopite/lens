module Gettext
  extend self

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
      DUMMY
      EOF
    end

    # Object representing a token from the grammar of gettext po files
    struct Token
      getter literal : String | Int32 | Int64 | Float64
      getter column : Int32 | Int64
      getter token_type : TokenTypes

      def initialize(@token_type, @literal, @column)
      end
    end
  end
end
