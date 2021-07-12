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

      Dir.glob("#{@locale_directory_path}/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        @_source[name] = File.read(gettext_file)
      end
    end

    # Scans loaded locale data into tokens parsing.
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
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
        scanner = POScanner.new(file_name, contents)
        tokens = scanner.scan

        tokenized_locales[file_name] = tokens
      end

      return tokenized_locales
    end

    # Parse tokens into message catalogues
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.parse(backend.scan)
    # ```
    def parse(token_hash)
      locale_catalogues = {} of String => Catalogue

      token_hash.each do |file_name, contents|
        parser = POParser.new(contents)
        catalogue = parser.parse

        catalogue = Catalogue.new(catalogue)

        if lang = catalogue.headers["Language"]?
          locale_catalogues[lang] = catalogue
        else
          locale_catalogues[file_name] = catalogue
        end
      end

      return locale_catalogues
    end

    # Create message catalogue from the loaded locale files
    #
    # Shortcut to avoid calling `scan` and `parse`
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.create # => Catalogue
    # ```
    def create
      return self.parse(self.scan)
    end
  end
end
