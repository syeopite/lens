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
    def parse : Hash(String, Catalogue)
      preprocessed_messages = {} of String => Hash(String, Hash(Int8, String))

      Dir.glob("#{@locale_directory_path}/**/*.po") do |gettext_file|
        name = File.basename(gettext_file)
        contents = POParser.new(name, File.read(gettext_file)).parse

        if preprocessed_messages.has_key?(name)
          # We're just going to use the size of the locale hash to mark files with the same name. This is a major
          # hack and should be optimized in the future.
          preprocessed_messages[name].merge!(contents)
        else
          preprocessed_messages[name] = contents
        end
      end

      locale_catalogues = {} of String => Catalogue
      preprocessed_messages.each do |name, translations|
        catalogue = Catalogue.new(translations)
        if lang = catalogue.headers["Language"]?
          locale_catalogues[lang] = catalogue
        else
          locale_catalogues[name] = catalogue
        end
      end

      return locale_catalogues
    end

    # Create message catalogue from the loaded locale files
    #
    # This is returned as a mapping of the language code to the catalogue
    # in which the language code is taken from the `Language` header. If
    # none can be found then the po file name is used as a fallback.
    #
    # As of v0.2 this is equivalent to `#parse`
    #
    # ```
    # backend = Gettext::POBackend.new("locales")
    # backend.create # => Hash(String, Catalogue)
    # ```
    def create : Hash(String, Catalogue)
      return self.parse
    end
  end
end
