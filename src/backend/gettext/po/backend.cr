module Gettext
  extend self

  # The backend for Gettext's PO files. This class contains methods to parse and interact with them.
  class POBackend
    # Create a new PO backend instance that reads from the given locale directory path
    #
    # ```
    # Gettext::POBackend.new("locales")
    # ```
    def initialize(@locale_directory_path : String)
      @had_error = false
      @_source = {} of String => String
    end

    # Loads all gettext files from configured directory path into the class
    #
    # ```
    # Gettext::POBackend.new("locales").load
    # ```
    def load
      @_source = self.open_files
    end

    # Scans loaded locale data into tokens for easier parsing.
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.load
    # backend.scan # => Array(Token)
    # ```
    def scan
      if @_source.empty?
        # TODO better error handling
        raise Exception.new("No locale files have been loaded yet. Did you forget to call
                             the .load() method?")
      end

      tokenized_locales = {} of String => Array(Token)
      @_source.each do |file_name, contents|
        scanner = POScanner.new(contents)
        tokens = scanner.scan

        tokenized_locales[file_name] = tokens
      end

      return tokenized_locales
    end

    # Parse tokens into message catalogues
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.load
    # backend.parse(backend.scan)
    # ```
    def parse(token_hash)
      locale_catalogues = {} of String => Catalogue

      token_hash.each do |file_name, contents|
        parser = Parser.new(contents)
        catalogue = parser.parse

        locale_catalogues[file_name] = Catalogue.new(catalogue)
      end

      return locale_catalogues
    end

    # Opens and reads all .po file from the locale directory
    private def open_files
      raw_locales = {} of String => String

      Dir.glob("#{@locale_directory_path}/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        raw_locales[name] = File.read(gettext_file)
      end

      return raw_locales
    end
  end

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
      return @plural_interpreter.interpret(n)
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
