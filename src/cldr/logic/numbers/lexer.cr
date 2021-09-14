require "../../../helpers/base/lexer"
require "./tokens"

# Module containing methods to handle CLDR number patterns
# EXPERIMENTAL
# TODO Write documentation
module CLDR::Numbers
  # EXPERIMENTAL
  # TODO Write documentation
  class PatternLexer < Lens::Base::Lexer(Token)
    # Scans a token from the source number pattern
    def scan_token
      @token = nil
      character = @reader.current_char
      @reader.next_char

      case character
      when '0'                                         then self.add_token(TokenTypes::DigitPlaceholder)
      when '1', '2', '3', '4', '5', '6', '7', '8', '9' then self.add_token(TokenTypes::RoundingSignifier)
      when '@'                                         then self.add_token(TokenTypes::SignificantDigitSignifier)
      when '#'                                         then self.add_token(TokenTypes::DigitPlaceholderNoFrontBackZeros)
      when '.'                                         then self.add_token(TokenTypes::DecimalSeparator)
      when '-'                                         then self.add_token(TokenTypes::MinusSign)
      when ','                                         then self.add_token(TokenTypes::GroupingSeparator)
      when 'E'                                         then self.add_token(TokenTypes::ExponentialSeparator)
      when '+'                                         then self.add_token(TokenTypes::PlusSign)
      when '%'                                         then self.add_token(TokenTypes::PercentSign)
      when '‰'                                         then self.add_token(TokenTypes::PerMilleSign)
      when ';'                                         then self.add_token(TokenTypes::SubPatternBoundary)
      when '¤'                                         then self.add_token(TokenTypes::CurrencySymbol)
      when '*'
        self.add_token(TokenTypes::PaddingSignifier, @reader.current_char.to_s)
        @reader.next_char
      when '\'' then self.process_string_token
      else           self.add_token(TokenTypes::Character, character.to_s)
      end
    end

    # Processes a string token
    #
    # This is mostly the same as the Gettext scanner
    # but with the string identifier changed to ' and
    # removal of escapes and newlines handling.
    private def process_string_token
      while true
        current_char = @reader.current_char
        if current_char == '\'' || self.at_end_of_source?
          break
        end

        self.advance_and_store
      end

      if self.at_end_of_source?
        raise LensExceptions::LexError.new("Number pattern: '#{@source}' ", "Unterminated string", @source, 1, @reader.pos - 1)
      end

      self.advance_and_store

      self.add_token(TokenTypes::StringLiteral, @io.to_s.strip("'"))
      @io.clear
    end
  end
end
