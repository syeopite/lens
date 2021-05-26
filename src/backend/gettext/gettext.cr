require "../base.cr"

module Gettext
  class Backend
    def initialize(@path : String)
      @had_error = false
      @_source = {} of String => Array(String)
    end

    # Loads all gettext files into the class
    def load
      @_source = self.open_files
    end

    # Scans loaded locale data into tokens for easier parsing.
    def scan
      if @_source.empty?
        raise Exception.new("No locale files have been loaded yet. Did you forget to call
                             the .load() method?")
      end

      tokenized_locales = {} of String => Array(Base::Token)
      @_source.each do |file_name, contents|
        scanner = Scanner.new(contents, self)
        tokens = scanner.scan

        tokenized_locales[file_name] = tokens
      end

      return tokenized_locales
    end

    private def open_files
      raw_locales = {} of String => Array(String)

      Dir.glob("#{@path}/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        raw_locales[name] = File.read_lines(gettext_file)
      end

      return raw_locales
    end
  end

  enum GettextTokens
    STRING
    PREV_MSGID
    MSGCTXT
    MSGID
    MSGID_PLURAL
    MSGSTR
    MSGSTR_PLURAL_ID
  end

  struct Token < Base::Token
    def initialize(@token_type : GettextTokens, @lexeme : String,
                   @literal : String?, @line : Int32)
    end
  end

  class Scanner
    def initialize(@_sourcel : Array(String), @backend_instance : Backend)
      @tokens = [] of Base::Token

      # Positional markers
      @_token_start_index = 0
      @_current_token_cursor_index = 0
      @_line = 1

      @_source = ""

    end

    def scan
      @_sourcel.each do |line|
        @_source = line
        @_token_start_index = 0
        @_current_token_cursor_index = 0

        while !self.at_end_of_source?
          @_token_start_index = @_current_token_cursor_index
          self.scan_current_token
        end

      end

      return @tokens
    end

    # Scans a token
    private def scan_current_token
      # Fetch current character
      character = @_source[@_current_token_cursor_index].to_s
      self.advance_cursor

      case character
      when "#"
        self.process_hashed_character()
      when "\""
        self.process_string_token()
      when "m"
        self.process_potential_keyword()
      when "["
        self.consume_till("]")
        # consume_till halted when we reached "]" so we'll consume it here.
        self.advance_cursor()
        self.add_token(GettextTokens::MSGSTR_PLURAL_ID, @_source[@_token_start_index..@_current_token_cursor_index-1].strip("[]"))
      when "\n"
        @_line += 1
      end
    end

    # Proccesses GNU Gettext comments.
    #
    # All of these is currently uneeded. However, if the future says that these are required:
    # the infrastructure is here to easily tokenize them.
    private def process_hashed_character
      case self.peek_at_next_character
      when "." # Extracted comments
        self.consume_till("\n")
      when ":" # Reference
        self.consume_till("\n")
      when "," # "#, " denotes flags
        self.consume_till("\n")
        # while self.peek_at_next_character != "\n" && !self.at_end_of_source?
        #   while self.peek_at_next_character != "," && !self.at_end_of_source?
        #     self.advance_cursor()
        #   end

        #   # If the second while loop is broken out of then that means we *might've* found a flag
        #   # we'll go ahead and check it aganist the hash of them.
        #   if flag = Gettext::FlagMap[@_source[@_token_start_index..@_current_token_cursor_index].strip("#, ")]?
        #     self.add_token(GettextTokens::FLAGS, literal) # WIP
        #   end
        # end
      when "|"
        self.consume_till("\n")
      else
        self.consume_till("\n")
      end
    end

    private def process_string_token()
      while self.peek_at_next_character() != "\"" && !self.at_end_of_source?()
        self.handle_quote_escapes()
        if self.peek_at_next_character() == "\n"
            @_line += 1
        end

        self.advance_cursor()
      end



      if self.at_end_of_source?
        raise Exception.new("Unterminated string! #{@_line}")
      end

      self.advance_cursor()
      literal = @_source[@_token_start_index..@_current_token_cursor_index-1].strip('"')
      self.add_token(GettextTokens::STRING, literal)

    end

    private def handle_quote_escapes()
      # Handle escapes
      if self.peek_at_next_character() == "\\"
        self.advance_cursor()
      end
    end

    private def process_potential_keyword
      while self.peek_at_next_character().char_at(0).alphanumeric? || self.peek_at_next_character() == "_"
        self.advance_cursor()
      end

      kw_text = @_source[@_token_start_index..@_current_token_cursor_index-1]

      begin
        kw = Gettext::GettextTokens.parse(kw_text.upcase)
      rescue ex
        return
      end

      self.add_token(kw) # WIP
    end

    private def consume_till(till)
      while self.peek_at_next_character() != till && !self.at_end_of_source?
        self.advance_cursor()
      end
    end

    private def advance_cursor
      @_current_token_cursor_index += 1
    end

    # Look ahead for the next character
    private def peek_at_next_character
      if self.at_end_of_source?
        return "\0"
      end

      return @_source[@_current_token_cursor_index].to_s
    end

    # Checks if the cursor is at the end of the source string
    private def at_end_of_source?
      return @_current_token_cursor_index >= @_source.size
    end

    # Appends a token to the final output list
    private def add_token(token_type : GettextTokens , literal : String = "")
      lexeme = @_source[@_token_start_index..@_current_token_cursor_index-1]
      @tokens << Gettext::Token.new(token_type, lexeme, literal, @_line)
    end
  end
end
