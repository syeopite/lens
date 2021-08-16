require "./tokens"
require "./scanner"

module Gettext
  # Parser for generating a hash of translation expressions out of lexed tokens for Gettext PO files.
  private class POParser < Lens::Base::Parser(Token, POTokens, POScanner(Token))
    # Creates a new parser instance from the given array of tokens
    def initialize(@file_name : String, source : String)
      @contents = {} of String => Hash(Int8, String)
      @token_iter = POScanner(Token).new(file_name, source)
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

    # Parse token list into hash of translation expressions
    #
    # ```
    # new_backend_instance = Gettext::POBackend.new("example/locales")
    # tokens = new_backend_instance.scan
    # Gettext::POParser.new(tokens).parse["example.po"] # => {"test" => {0=> "translated-test"}}
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
