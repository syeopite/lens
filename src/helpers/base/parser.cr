# Base parser all parser inherits from. Contains the skeleton for building one
abstract class Lens::Base::Parser(TOKEN, TOKEN_TYPE, SCANNER)
  # Dummy variables
  @previous_token : TOKEN = TOKEN.new(TOKEN_TYPE::DUMMY, "", 0)
  @current_token : TOKEN = TOKEN.new(TOKEN_TYPE::DUMMY, "", 0)

  # Creates a new parser instance from the given array of tokens
  def initialize(source : String)
    @token_iter = SCANNER.new(source)
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
    if @current_token.token_type == TOKEN_TYPE::EOF
      return true
    end
    return false
  end

  # Advance token iterator by one and returns the result
  private def advance_token_iterator
    @previous_token = @current_token
    token = @token_iter.next

    if token.is_a? Iterator::Stop
      @current_token = TOKEN.new(TOKEN_TYPE::EOF, "", 0)
    else
      @current_token = token
    end

    return @current_token
  end

  # Fetches and yields the next token. Sets the @previous_token after yielding.
  private def token_reader
    while true
      token = @token_iter.next
      if token.is_a? Iterator::Stop
        break
      end

      @current_token = token
      yield token
      @previous_token = @current_token
    end
  end

  # Begins the parsing chain. Must return the finished result, whatever it may be.
  abstract def parse
end
