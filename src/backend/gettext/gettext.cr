require "./**"

module Gettext
  extend self

  # Gettext message catalogue. Contains methods for handling translations
  class Catalogue
    @headers : Hash(String, String)
    @plural_interpreter : PluralForm::Interpreter?

    def initialize(@contents : Hash(String, Hash(Int8, String)))
      @headers = {} of String => String

      headers = [] of String
      @contents[""]?.try &.[0].split("\n") { |v| headers << v if !v.empty? } || nil

      headers.each do |h|
        header = h.split(":", limit: 2)
        next if header.size <= 1
        @headers[header[0]] = header[1].strip
      end

      if plural_form_expression = @headers["Plural-Forms"]?
        # Get interpreter for plural expressions
        expressions = PluralForm::Parser.new(PluralForm::Scanner.new(plural_form_expression).scan).parse
        @plural_interpreter = PluralForm::Interpreter.new(expressions)
      else
        @plural_interpreter = nil
      end
    end

    private def process_plural(n)
      return @plural_interpreter.not_nil!.interpret(n)
    end

    # Fetch the translated message for the specific ID. If none can be found the given ID is returned.
    def gettext(id : String)
      begin
        return @contents[id][0]
      rescue KeyError
        return id
      end
    end

    # Fetches the translated message for the specific ID with the correct plural form. Returns either the singular or plural id if none can be found.
    def ngettext(id : String, plural_id, n)
      if @plural_interpreter.nil?
        return id
      end

      begin
        return @contents[id][self.process_plural(n)]
      rescue KeyError
        if n == 0
          return id
        else
          return plural_id
        end
      end
    end

    # Fetches the translated message for the specific ID that is bound by context. If none can be found the given ID is returned.
    def pgettext(context, id)
      begin
        return @contents["#{context}\u0004#{id}"][0]
      rescue KeyError
        return id
      end
    end

    # Fetches the translated message for the specific ID that is bound by context with the correct plural form.
    def npgettext(context, id, plural_id, n)
      if @plural_interpreter.nil?
        return id
      end

      begin
        return @contents["#{context}\u0004#{id}"][self.process_plural(n)]
      rescue KeyError
        if n == 0
          return id
        else
          return plural_id
        end
      end
    end
  end
end
