module Gettext
  # A scanner to tokenize the grammar of gettext po files.
  #
  # Inspired by the [scanner in the python project Babel.](https://github.com/python-babel/babel/blob/master/babel/messages/pofile.py)
  class POScanner
    # Creates a new scanner instance that scans from the given source, which is usually an Array of lines from a Gettext file (.po).
    #
    # ```
    # lines = ["msgid \"Example\"", "msgstr \"Translation\""]
    # Gettext::Backend.POScanner.new(lines)
    # ```
    def initialize(@source : Array(String))
      @tokens = [] of Token

      # Positional markers
      @_token_start_index = 0
      @_current_token_cursor_index = 0
      @_line = 1
    end

    # Tokenizes the grammar of gettext files (.po version) into tokens for parsing
    #
    # ```
    # lines = ["msgid \"Example\"", "msgstr \"Translation\""]
    # scanner = Gettext::Backend.POScanner.new(lines)
    # scanner.scan() # => Array(Token)
    # ```
    def scan()
      @source.each do | line |
        self.scan_for_token(line)
      end

      return @tokens
    end

    # Recursively process a line from the .po file.
    #
    # Any token that is found would get removed from the line, tokenized and appended to the output list. Afterwards,
    # the remaining line is dropped into this method for further processing.
    private def scan_for_token(line)
      if line.starts_with?("[")
        self.process_plural_id(line)
      elsif line.starts_with?("\"")
        self.add_token(GettextTokens::STRING, line.strip("\""))
      else
        self.process_potential_keyword(line)
      end
    end

    # Tokenizes the plural identifier of the msgstr
    private def process_plural_id(line)
      line_without_plural_identifier = ""
      identifier = String.build do | identifier |
        line.each_char_with_index do |char, index|
          char = char.to_s
          if char == "]"
            identifier << char
            line_without_plural_identifier = line[index+1..]
            break

          # If we've reached the quite of a keyword line then that mean the plural identifier
          # wasn't terminated.
          elsif char == "\""
            raise Exception.new "Unterminated '[' in msgstr at line #{@_line}"
          end

          identifier << char
        end
      end

      self.add_token(GettextTokens::MSGSTR_PLURAL_ID, identifier)
      self.scan_for_token(line_without_plural_identifier)
    end

    # Tokenizes any potential keywords from the given line.
    private def process_potential_keyword(line)
      KEYWORDS.each do |name, type|
        # Keyword line
        if line.starts_with?(name)
          self.add_token(type)

          keyword_argument = line[name.size..]
          self.scan_for_token(keyword_argument.strip(" "))
        end
      end
    end

    # Appends a token to the final token list
    private def add_token(token_type, literal="")
      @tokens << Token.new(token_type, literal, @_line)
    end
  end
end
