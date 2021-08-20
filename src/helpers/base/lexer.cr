# Base lexer all lexers inherits from. Contains the skeleton for building one
#
# All lexers are iterators in order to allow the parsing and lexing
# stage to take place simultaneously. They also contain an `#scan`
# method, which returns an array of tokens, in case a more step-by-step
# process is needed
abstract class Lens::Base::Lexer(T)
  include Iterator(T)
  @token : T?
  @error_column : Int32?

  def initialize(@source : String)
    @token = nil
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

  # Tokenizes the source fully and return an array of tokens.
  #
  # Assume we have a `Scanner`
  # ```
  # scanner = Scanner(Token).new(contents)
  # scanner.scan # => Array(Tokens)
  # ```
  def scan
    tokens = [] of T

    while !self.at_end_of_source?
      self.scan_token
      next if @token.nil?
      tokens << @token.not_nil!
    end

    return tokens
  end

  # Scans and returns the next token on each call.
  # Iterates through the given C expression and return a Token on each run
  #
  # Assume we have a `Scanner`
  # ```
  # scanner = Scanner(Token).new(contents)
  # scanner.next # => Token
  # ...
  # scanner.next # => Iterator::Stop::INSTANCE
  # ```
  def next
    if !self.at_end_of_source?
      self.scan_token
      return self.next if @token.nil?
      return @token.not_nil!
    end

    return Iterator::Stop::INSTANCE
  end

  private abstract def scan_token

  # Checks if scanner is at end of source
  private def at_end_of_source?
    if !@reader.has_next?
      return true
    else
      return false
    end
  end

  # Consume till a specific character
  private def consume_till(till, store = false)
    while true
      if self.at_end_of_source? || @reader.current_char == till
        break
      end

      store ? self.advance_and_store : self.advance
    end
  end

  # Converse of `#consume_till`, continually consumes a token while it matches the given char.
  private def consume_while(match, store = false)
    while true
      if self.at_end_of_source? || @reader.current_char != match
        break
      end

      store ? self.advance_and_store : self.advance
    end
  end

  # Advance reader by one character
  private def advance
    @column += 1
    @reader.next_char
    return @reader.current_char
  end

  # Stores current character in IO and advance reader
  private def advance_and_store
    @column += 1
    @io << @reader.current_char
    @reader.next_char
  end

  # Raise unexpected character error
  private def unexpected_character(name)
    # We don't need the @column variable in this case as the Plural Form expression isn't expected to be multiple lines
    @error_column = @column
    consume_till('\n', store = true)
    @line_accumulator << @io.to_s
    raise LensExceptions::LexError.new(name, "Unexpected character", @line_accumulator.to_s, @line, @error_column.not_nil!)
  end

  # Reset the state of line accumulator. This should be ran on every new line.
  #
  # If an error column is set then that means the line accumulator is currently consuming
  # till '\n' for error reporting. Thus we'll skip it.
  private def reset_line_accumulator_state
    return if !@error_column.nil?
    @column = 0
    @line_accumulator.clear
    @line += 1
  end

  # Appends a token to the final token list
  private def add_token(token_type, literal = "")
    @token = T.new(token_type, literal, @reader.pos)
  end
end
