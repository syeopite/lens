require "../../../helpers/base/lexer"
require "../../../helpers/*"
require "./tokens"

module Gettext
  # A scanner to tokenize the grammar of gettext po files.
  private class POScanner < Lens::Base::MultiLineLexer(Token)
    # Creates a new scanner instance that scans from the given contents of a Gettext file (.po).
    #
    # ```
    # source = "msgid \"Hello There\"\nmsgstr \"Translation\""
    # Gettext::POScanner.new(source)
    # ```
    def initialize(@file_name : String, @source : String)
      super
    end

    # Scans a token from the contents of the gettext file
    #
    # Any token that is found would get appended into the output list.
    private def scan_token
      character = @reader.current_char
      @line_accumulator << character
      @token = nil
      self.advance

      case character
      when '"' then self.process_string_token
      when 'm'
        @io << character
        self.process_potential_keyword
      when '[' then self.process_plural_form
      when '#' then self.process_hashed_character
      when ' '
      when '\n' then self.reset_line_accumulator_state
      else           self.unexpected_character(@file_name)
      end
    end

    # Processes Gettext comments.
    #
    # All of these is currently unnecessary. However, if the future says that these are required
    # the infrastructure is here to easily tokenize them.
    private def process_hashed_character
      case @reader.current_char
      when "." then self.consume_till('\n')
      when ":" then self.consume_till('\n')
      when "," then self.consume_till('\n')
      when "|" then self.consume_till('\n')
      else          self.consume_till('\n')
      end
    end

    private def process_string_token
      while true
        case @reader.current_char
        when '"' then break self.advance # consumes '"'
        when '\n' then self.unterminated_string
        when '\\'
          case self.advance
          when 'n' then @io << "\n"
          else          @io << @reader.current_char
          end

          next self.advance
        end

        return self.unterminated_string if self.at_end_of_source?
        self.advance_and_store
      end

      @line_accumulator << "#{@io}\""
      self.add_token(POTokens::STRING, @io.to_s)
      @io.clear
    end

    private def process_potential_keyword
      while true
        character = @reader.current_char

        if !character.alphanumeric? && character != '_'
          break
        end

        self.advance_and_store
      end

      # We added an additional 'm' to the IO before calling this method. However, the line accumulator already
      # contains one at the start so we'll just go ahead and strip that one.
      @line_accumulator << @io.to_s[1..]
      begin
        kw = POTokens.parse(@io.to_s.upcase)
        self.add_token(kw)
        @io.clear
      rescue ex
        return
      end
    end

    private def process_plural_form
      while true
        current_char = @reader.current_char
        if current_char == ']' || self.at_end_of_source?
          break self.advance # Consume '['
        end

        self.advance_and_store
      end

      @line_accumulator << "#{@io}]"
      self.add_token(POTokens::PLURAL_FORM, @io.to_s)
      @io.clear
    end

    private def unterminated_string
      @line_accumulator << @io.to_s
      @error_column = @column
      raise LensExceptions::LexError.new(@file_name, "Unterminated string", @line_accumulator.to_s, @line, @error_column.not_nil!)
    end
  end
end
