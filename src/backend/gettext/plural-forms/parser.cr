require "../plural-forms/tokens"

module Gettext
  extend self

  module PluralForm
    extend self

    # Parser for generating plural-form expression ASTs out of an array of tokens
    #
    #
    # [Based on this parser from crafting interpreters](https://www.craftinginterpreters.com/parsing-expressions.html)
    class Parser
      @tokens : Array(Token)
      @token_iter : Iterator(Token)
      @previous_token : Token? = nil
      @current_token : Token? = nil

      # Creates a new parser instance with the array of tokens from the `PluralForm::Scanner` as input.
      #
      # ```
      # plural_form_scanner = Gettext::PluralForm::Scanner.new("nplurals=2; plural=(n > 1);")
      # tokens = plural_form_scanner.scan
      # plural_form_parser = Gettext::PluralForm::Parser.new(tokens)
      # ```
      def initialize(@tokens)
        @token_iter = @tokens.each
      end

      # Parse an plural-form expression into AST trees
      #
      # ```
      # plural_form_parser = PluralForm::Parser.new(tokens)
      # plural_form_parser.parse # => Array(Expression)
      # ```
      private def expression
        return self.assignment
      end

      # Most of the binary expression syntax is the same so we'll just define it via macro
      # Generate AST for most of the binary expressions
      {% for binary_expr in [
                              # Name, object, lower precedence function, tokentypes
                              ["logical_or", "Logical", "logical_and", "TokenTypes::OR"],
                              ["logical_and", "Logical", "equality", "TokenTypes::AND"],
                              ["equality", "Binary", "comparison", "TokenTypes::NOT_EQUAL, TokenTypes::EQUAL_EQUAL"],
                              ["comparison", "Binary", "term", "TokenTypes::GREATER, TokenTypes::GREATER_EQUAL, TokenTypes::LESS, TokenTypes::LESS_EQUAL"],
                              ["term", "Binary", "factor", "TokenTypes::MINUS, TokenTypes::PLUS"],
                              ["factor", "Binary", "unary", "TokenTypes::SLASH, TokenTypes::STAR, TokenTypes::MOD"],
                            ] %}
      private def {{binary_expr[0].id}}
        expression = self.{{binary_expr[2].id}}()

        while self.match({{binary_expr[3].id}})
          operator = @previous_token.not_nil!
          right_expression = self.{{binary_expr[2].id}}()
          expression = {{binary_expr[1].id}}.new(expression, operator, right_expression)
        end

        return expression
      end
      {% end %}

      # Parses an assignment expression into an AST
      private def assignment
        expression = self.conditional

        if self.match(TokenTypes::EQUAL)
          equals = @previous_token
          value = self.assignment

          if expression.is_a? Variable
            return Assignment.new(expression.name, value)
          end

          raise LensExceptions::ParseError.new("Invalid assignment detected when parsing 'Plural-Forms' at" \
                                               " Column #{@current_token.not_nil!.column}\n")
        end

        return expression
      end

      # Parses a C conditional expression into an AST
      private def conditional
        expression = self.logical_or

        if self.match(TokenTypes::QUESTION)
          then_branch = self.expression
          self.consume(TokenTypes::COLON, "Plural-form header missing colon at column: #{@current_token.not_nil!.column}")
          else_branch = self.conditional
          expression = Conditional.new(expression, then_branch, else_branch)
        end

        return expression
      end

      # Parses a unary expression into an AST
      private def unary
        if self.match(TokenTypes::NOT, TokenTypes::MINUS)
          operator = @previous_token.not_nil!
          right_expression = self.unary

          return Unary.new(operator, right_expression)
        end

        return self.primary
      end

      private def primary
        if self.match(TokenTypes::NUMBER)
          return Literal.new(@previous_token.not_nil!.literal.as(Int32 | Int64 | Float64))
        end

        if self.match(TokenTypes::IDENTIFIER)
          return Variable.new(@previous_token.not_nil!.literal.as(String))
        end

        if self.match(TokenTypes::LEFT_PAREN)
          expression = self.expression
          self.consume(TokenTypes::RIGHT_PAREN, "Plural-form header missing ')' at column: #{@current_token.not_nil!.column}")
          return Grouping.new(expression)
        end

        raise LensExceptions::ParseError.new("Expecting plural-form expression!")
      end

      # Checks to see if the current_token is any of the given types. If so consumes the token.
      private def match(*token_types)
        token_types.each do |type|
          if self.check(type)
            self.advance_token_iterator
            return true
          end
        end
      end

      # Checks to see if the current token is the given type
      private def check(token_type)
        if !self.is_at_end?
          return @current_token.not_nil!.token_type == token_type
        end
      end

      # Consumes the next token if it's of the given type. Raises otherwise.
      private def consume(token_type, error_message)
        if self.check(token_type)
          return self.advance_token_iterator
        else
          raise LensExceptions::ParseError.new(error_message)
        end
      end

      # Checks to see if we're at the end of the token iterator
      private def is_at_end?
        if @current_token == Iterator::Stop
          return true
        end
        return false
      end

      # Advance token iterator by one and returns the result
      private def advance_token_iterator
        @previous_token = @current_token
        char = @token_iter.next

        if char.is_a? Iterator::Stop
          raise LensExceptions::ParseError.new("Unexpected end of token iteration when parsing 'Plural-Forms' at" \
                                               " Column #{@current_token.not_nil!.column}\n" \
                                               "Perhaps you've forgotten an ';'?\n"
          )
        else
          @current_token = char
        end

        return @current_token
      end

      # Yields a token from the token array
      private def token_reader
        @token_iter.each do |token|
          @current_token = token
          yield token
          @previous_token = @current_token
        end
      end

      # Parse an array of tokens into abstract syntax trees that represents a plural-form expression (C)
      #
      # ```
      # plural_form_scanner = Gettext::PluralForm::Scanner.new("nplurals=2; plural=(n > 1);")
      # tokens = plural_form_scanner.scan
      # plural_form_parser = Gettext::PluralForm::Parser.new(tokens)
      # plural_form_parser.parse # => Array(Expressions)
      # ```
      def parse
        expressions = [] of Expression
        self.token_reader do |token|
          expressions << self.expression
        end

        return expressions
      end
    end
  end
end
