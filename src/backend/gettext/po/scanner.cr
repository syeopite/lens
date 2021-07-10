module Gettext
  # A scanner to tokenize the grammar of gettext po files.
  class POScanner
    # Creates a new scanner instance that scans from the given contents of a Gettext file (.po).
    #
    # ```
    # source = "msgid \"Hello There\"\nmsgstr \"Translation\""
    # Gettext::Backend.POScanner.new(source)
    # ```
    def initialize(@source : String)
      @tokens = [] of Token

      @reader = Char::Reader.new(@source)
      @io = IO::Memory.new

      # Positional markers
      @token_start_index = 0
      @current_token_cursor_index = 0
      @line = 1
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
      @reader.next_char

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
        @line += 1
      else
        # TODO better error handling
        raise Exception.new("Unexpected character '#{character}' at line: #{@line}")
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
          raise Exception.new("Unterminated string at line: #{@line}")
        end

        # Handle escapes
        if current_char == '\\'
          case @reader.next_char
          when 'n'
            @io << "\n"
          end

          @reader.next_char
          next
        end

        self.advance_and_store
      end

      if self.at_end_of_source?
        raise Exception.new("Unterminated string at line: #{@line}")
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
          @reader.next_char
          break
        end

        self.advance_and_store
      end

      self.add_token(POTokens::PLURAL_FORM, @io.to_s)
      @io.clear
    end

    private def consume_till(till)
      while true
        if self.at_end_of_source? || @reader.current_char == till
          break
        end

        @reader.next_char
      end
    end

    private def at_end_of_source?
      if !@reader.has_next?
        return true
      else
        return false
      end
    end

    private def advance_and_store
      @io << @reader.current_char
      @reader.next_char
    end

    # Appends a token to the final token list
    private def add_token(token_type, literal = "")
      @tokens << Token.new(token_type, literal, @line)
    end
  end
end
