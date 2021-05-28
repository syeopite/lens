require "../base.cr"

module Gettext
  class Backend
    def initialize(@path : String)
      @had_error = false
      @_source = {} of String => Array(String)
    end

    # Loads all gettext files from configured directory path into memory
    #
    # ```
    # Gettext::Backend.new("locales").load # => {locale_name => Array(String),...}
    # ```
    def load
      @_source = self.open_files
    end

    # Scans loaded locale data into tokens for easier parsing.
    def scan
      if @_source.empty?
        # TODO better error handling
        raise Exception.new("No locale files have been loaded yet. Did you forget to call
                             the .load() method?")
      end

      tokenized_locales = {} of String => Array(Token)
      @_source.each do |file_name, contents|
        scanner = Scanner.new(contents, self)
        tokens = scanner.scan()

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

  private enum GettextTokens
    STRING
    PREV_MSGID
    MSGCTXT
    MSGID
    MSGID_PLURAL
    MSGSTR
    MSGSTR_PLURAL_ID
  end

  private KEYWORDS = {
    "msgctxt" => GettextTokens::MSGCTXT,
    "msgid" => GettextTokens::MSGID,
    "msgid_plural" => GettextTokens::MSGID_PLURAL,
    "msgstr" => GettextTokens::MSGSTR
  }

  private struct Token < Base::Token
    def initialize(@token_type : GettextTokens, @literal : String?, @line : Int32)
    end
  end

  # A scanner to tokenize the grammar of gettext po files.
  #
  # Inspired by the [scanner in the python project Babel.](https://github.com/python-babel/babel/blob/master/babel/messages/pofile.py)
  class Scanner
    def initialize(@source : Array(String), @backend_instance : Backend)
      @tokens = [] of Token

      # Positional markers
      @_token_start_index = 0
      @_current_token_cursor_index = 0
      @_line = 1
    end

    # Tokenizes the grammar of gettext files (.po version) into tokens for parsing
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
      elsif line.starts_with?("#")
      elsif line.starts_with?("\n")
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
