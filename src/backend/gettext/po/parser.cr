module Gettext
  extend self

  # Parser for generating a hash of translation expressions out of lexed tokens for Gettext PO files.
  class Parser
    @token_iter : Iterator(Token)

    # Dummy variables
    @previous_token : Token = Token.new(POTokens::DUMMY, nil, 0)
    @current_token : Token = Token.new(POTokens::DUMMY, nil, 0)

    # Creates a new parser instance from the given array of tokens
    def initialize(@tokens : Array(Token))
      @token_iter = @tokens.each
      @contents = {} of String => Hash(Int8, String)
    end

    # Parse a full translation block (msgid, msgid_plural, msgstr, etc) and appends the result to the catalogue
    private def translation_expression
      msgctxt = self.msgctxt
      msgid = self.msgid

      msgid_plural = nil
      if self.match(POTokens::MSGID_PLURAL)
        msgid_plural = self.string
      end

      if !msgctxt.nil?
        msgid = "#{msgctxt}\u0004#{msgid}"
        if !msgid_plural.nil?
          msgid_plural = "#{msgctxt}\u0004#{msgid_plural}"
        end
      end

      translation_strings = self.msgstr

      if msgid_plural
        @contents[msgid_plural] = translation_strings
      end

      @contents[msgid] = translation_strings
    end

    # Parse a msgid expression. Raises when it doesn't exist
    private def msgid
      self.consume(POTokens::MSGID, "Missing msgid expression at line #{@current_token.line}")
      return self.string
    end

    # Parse an msgctxt expression if it exists. Returns nil otherwise.
    private def msgctxt
      if self.match(POTokens::MSGCTXT)
        return self.string
      end
    end

    # Parse msgstr expressions
    private def msgstr
      self.consume(POTokens::MSGSTR, "Missing msgstr expression at line #{@current_token.line}")
      self.match(POTokens::PLURAL_FORM) # Skip the first PLURAL_FORM expression if it has one
      value = self.string

      msgstr_dict = {} of Int8 => String
      while self.match(POTokens::MSGSTR) && !self.is_at_end?
        # If there's yet another msgstr expression then
        # the next token will have to be plural form indicator.
        # If it isn't then it's likely caused by the fact that
        # the user forgot to add in a msgid expression
        self.consume(POTokens::PLURAL_FORM, "Missing plural form indicator at line #{@current_token.line}. Perhaps you forgotten to add a msgid expression for the current block?")

        plural_form = @previous_token.literal.not_nil!.to_i8
        self.advance_token_iterator
        str = self.string
        msgstr_dict[plural_form] = str
      end

      msgstr_dict[0.to_i8] = value
      return msgstr_dict
    end

    # Builds a crystal string from string tokens
    private def string
      str = String.build do |str|
        while @current_token.token_type == POTokens::STRING && !self.is_at_end?
          str << @current_token.literal
          self.advance_token_iterator
        end
      end

      return str
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
        raise Exception.new(error_message)
      end
    end

    # Checks to see if we're at the end of the token iterator
    private def is_at_end?
      if @current_token.token_type == POTokens::EOF
        return true
      end
      return false
    end

    # Advance token iterator by one and returns the result
    private def advance_token_iterator
      @previous_token = @current_token
      char = @token_iter.next

      if char.is_a? Iterator::Stop
        raise Exception.new("Unreachable")
      else
        @current_token = char
      end

      return @current_token
    end

    # Parse token list into hash of translation expressions
    #
    # ```
    # new_backend_instance = Gettext::POBackend.new("example/locales")
    # new_backend_instance.load
    # catalogues = new_backend_instance.parse(new_backend_instance.scan)["example.po"] # => {"test" => {0=> "translated-test"}}
    # ```
    def parse
      # Skip dummy @current_token
      self.advance_token_iterator

      while !self.is_at_end?
        self.translation_expression
      end

      return @contents
    end
  end
end
