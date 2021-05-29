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
      @_source = {} of String => Array(String)
    end

    # Loads all gettext files from configured directory path into memory
    #
    # ```
    # Gettext::POBackend.new("locales").load # => {locale_name => Array(String),...}
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
        tokens = scanner.scan()

        tokenized_locales[file_name] = tokens
      end

      return tokenized_locales
    end

    # Opens and reads all .po file from the locale directory
    private def open_files
      raw_locales = {} of String => Array(String)

      Dir.glob("#{@locale_directory_path}/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        raw_locales[name] = File.read_lines(gettext_file)
      end

      return raw_locales
    end
  end
end