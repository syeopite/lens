module Gettext
  extend self

  # The backend for Gettext's PO files. This class contains methods to parse and interact with them.
  struct POBackend < Backend
    # Create a new PO backend instance that reads from the given locale directory path
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
    # backend.parse # => Hash(String, Catalogue)
    # ```
    define_public_parse_function("po")

    # Internal parse method.
    private def parse_(file_name, io : IO)
      return POParser.new(file_name, io.gets_to_end).parse
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
