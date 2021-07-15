module Gettext
  extend self

  # The backend for Gettext's PO files. This class contains methods to parse and interact with them.
  struct POBackend
    # Create a new PO backend instance that reads from the given locale directory path
    #
    # NOTE
    # Any files that has the same name is assumed to be apart of the same locale since we don't know the
    # specific language header for them yet.
    #
    # ```
    # Gettext::POBackend.new("locales")
    # ```
    def initialize(@locale_directory_path : String)
      @had_error = false
      @_source = {} of String => String

      # Handle subfolders
      Dir.glob("#{@locale_directory_path}/**/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        if @_source.has_key?(name)
          # We're just going to use the end of transmission character to mark files with the same name. This is a major
          # back and should be optimized in the future.
          @_source[name + @_source.size.to_s] = File.read(gettext_file)
        else
          @_source[name] = File.read(gettext_file)
        end
      end
    end

    # Scans loaded locale data into tokens parsing.
    #
    # Returned as a mapping of the po file name to the token array
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.scan # => Array(Token)
    # ```
    def scan : Hash(String, Array(Token))
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
    # This is returned as a mapping of the language code to the catalogue
    # in which the language code is taken from the `Language` header. If
    # none can be found then the po file name is used as a fallback.
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.parse(backend.scan) # => Hash(String, Catalogue)
    # ```
    def parse(token_hash) : Hash(String, Catalogue)
      locale_catalogues = {} of String => Catalogue
      preprocessed_messages = {} of String => Hash(String, Hash(Int8, String))

      token_hash.each do |file_name, contents|
        parser = POParser.new(contents)
        messages = parser.parse

        # During the init method we went ahead and added a suffix number
        # to the end of the file name for locales with the same file name. (They're
        # assumed to be the same language) Therefore we can't create a catalogue till we
        # merged their contents. For now we'll just append everything to a preprocessed_messages hash.
        preprocessed_messages[file_name] = messages
      end

      locale_catalogues = self.create_catalogues_and_merge_duplicate_files(preprocessed_messages)

      return locale_catalogues
    end

    # Merge parsed contents of duplicate Gettext keys together and create catalogue objects
    #
    # OPTIMIZE
    private def create_catalogues_and_merge_duplicate_files(preprocessed_messages)
      locale_catalogues = {} of String => Catalogue

      # First we'll select all of the initial files. (The first ones opened by IO before any duplicates)
      initial_files = preprocessed_messages.keys.select! { |i| !i[-1].number? }

      initial_files.each do |base_file_name|
        base_messages = preprocessed_messages[base_file_name]

        # Now we'll fetch all of the duplicate keys
        duplicate_keys = preprocessed_messages.keys.select! { |i| i.starts_with?(base_file_name) }

        # We're merge the values (parsed messages) of the duplicate keys, if any, with our base messages
        # NOTE this would overwrite any existing keys.
        duplicate_keys.each { |duplicate| base_messages.merge!(preprocessed_messages[duplicate]) }

        # Finally we can create our catalogues
        catalogue = Catalogue.new(base_messages)
        if lang = catalogue.headers["Language"]?
          locale_catalogues[lang] = catalogue
        else
          locale_catalogues[base_file_name] = catalogue
        end
      end

      return locale_catalogues
    end

    # Create message catalogue from the loaded locale files
    #
    # Shortcut to avoid calling `scan` and `parse`
    #
    # This is returned as a mapping of the language code to the catalogue
    # in which the language code is taken from the `Language` header. If
    # none can be found then the po file name is used as a fallback.
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.create # => Hash(String, Catalogue)
    # ```
    def create : Hash(String, Catalogue)
      return self.parse(self.scan)
    end
  end
end
