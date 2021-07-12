require "../../../helpers/*"

module Gettext
  # A scanner to tokenize the grammar of gettext po files.
  private class POScanner
    @error_column : Int32?

    # Creates a new scanner instance that scans from the given contents of a Gettext file (.po).
    #
    # ```
    # source = "msgid \"Hello There\"\nmsgstr \"Translation\""
    # Gettext::Backend.POScanner.new(source)
    # ```
    def initialize(@file_name : String, @source : String)
      @tokens = [] of Token

      @reader = Char::Reader.new(@source)
      @io = IO::Memory.new

      # Positional markers. Mainly used for error handling
      @line = 1
      @column = 0
      @error_column = nil

      # Latches onto all characters on the current line to display
      # in case of error.
      @line_accumulator = IO::Memory.new
    end

    # Tokenize the grammar of gettext files (.po version) into tokens for parsing
    #
    # ```
    # source = "msgid \"Hello There\"\nmsgstr \"Translation\""
    # scanner = Gettext::Backend.POScanner.new(source)
    # scanner.scan # => Array(Token)
    # ```
    def scan
      while !self.at_end_of_source?
        self.scan_token
      end

      self.add_token(POTokens::EOF)
      return @tokens
    end

    # Scans a token from the contents of the gettext file
    #
    # Any token that is found would get appended into the output list.
    private def scan_token
      character = @reader.current_char
      @line_accumulator << character
      self.advance

      case character
      when '"'
        @io << character
        self.process_string_token
      when 'm'
        @io << character
        self.process_potential_keyword
      when '['
        self.process_plural_form
      when '#'
        self.process_hashed_character
      when ' '
      when '\n'
        return if !@error_column.nil?
        @column = 0
        @line_accumulator.clear
        @line += 1
      else
        @error_column = @column - 1
        consume_till('\n', store = true)
        @line_accumulator << @io.to_s

        raise LensExceptions::LexError.new(@file_name, "Unexpected character", @line_accumulator.to_s, @line, @error_column.not_nil!)
      end
    end

    # Proccesses Gettext comments.
    #
    # All of these is currently uneeded. However, if the future says that these are required
    # the infrastructure is here to easily tokenize them.
    private def process_hashed_character
      case @reader.current_char
      when "."
        self.consume_till('\n')
      when ":"
        self.consume_till('\n')
      when ","
        self.consume_till('\n')
      when "|"
        self.consume_till('\n')
      else
        self.consume_till('\n')
      end
    end

    private def process_string_token
      while true
        current_char = @reader.current_char
        if current_char == '"' || self.at_end_of_source?
          break
        elsif current_char == '\n'
          @line_accumulator << @io.to_s.lstrip("\"") # Remove the extra " added before calling current method
          @error_column = @column
          raise LensExceptions::LexError.new(@file_name, "Unterminated string", @line_accumulator.to_s, @line, @error_column.not_nil!)
        end

        # Handle escapes
        if current_char == '\\'
          case self.advance
          when 'n'
            @io << "\n"
          else
            @io << @reader.current_char
          end

          self.advance
          next
        end

        self.advance_and_store
      end

      @line_accumulator << @io.to_s.lstrip("\"") # Remove the extra " added before calling current method

      if self.at_end_of_source?
        @error_column = @column
        raise LensExceptions::LexError.new(@file_name, "Unterminated string", @line_accumulator.to_s, @line, @error_column.not_nil!)
      end

      self.advance_and_store

      self.add_token(POTokens::STRING, @io.to_s.strip("\""))
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

      @line_accumulator << @io.to_s.lstrip("m") # Remove the extra m added before calling current method
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
          self.advance
          break
        end

        self.advance_and_store
      end

      @line_accumulator << "#{@io}]"
      self.add_token(POTokens::PLURAL_FORM, @io.to_s)
      @io.clear
    end

    private def consume_till(till, store = false)
      while true
        if self.at_end_of_source? || @reader.current_char == till
          break
        end

        store ? self.advance_and_store : self.advance
      end
    end

    private def at_end_of_source?
      if !@reader.has_next?
        return true
      else
        return false
      end
    end

    # Advance reader by one character
    private def advance
      @reader.next_char
      @column += 1

      return @reader.current_char
    end

    # Advance reader by one character and store in IO
    private def advance_and_store
      @io << @reader.current_char
      self.advance
    end

    # Appends a token to the final token list
    private def add_token(token_type, literal = "")
      @tokens << Token.new(token_type, literal, @line)
    end
  end
end
