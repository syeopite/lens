# Namespace for logic relating to the [GNU Gettext](https://www.gnu.org/software/gettext/) format
#
# Gettext is typically separated into two files: `.po` and `.mo`. Both of these formats are fully supported
# by Lens with either the `Gettext::MOBackend` or `Gettext::POBackend` backends.
#
# For more information, please see their respective documentations.
#
# All functionality (except flags) of Gettext are implemented.
module Gettext
  # Base backend all Gettext backends inherits from.
  private abstract struct Backend
    # Define public API to interact with internal `#parse_` method and create Catalogue objects out of the results.
    #
    # The method in question uses the @locale_directory_path to glob for files ending with the given
    # ext. Afterwards, it is opened as an IO and passed into the internal #parse_ method. The results of which,
    # is a `Hash(String, Hash(Int8, String))`. A mapping of the msgid to a hash of the plural-form (default 0) to
    # the translated variant.
    #
    # After which, the results would be merged within the preprocessed_messages hash in order to allow for multiple
    # files for the same language. The key of which depends on whether or not the Language header is defined. If not,
    # the file name will be used as the key.
    macro define_public_parse_function(file_ext)
      def parse : Hash(String, Catalogue)
        # Language Code / File name => {Translations, processed headers}
        preprocessed_messages = {} of String => Hash(String, Hash(Int8, String))

        Dir.glob("#{@locale_directory_path}/**/*.#{ {{file_ext}} }") do | gettext_file |
          name = File.basename(gettext_file)

          contents = File.open(gettext_file) do |file|
            self.parse_(name, io: file)
          end

          # Extract header information to compare language code
          header = extract_headers(contents)

          if (lang = header["Language"]?) && (!lang.empty?)
            if preprocessed_messages.has_key?(lang)
              preprocessed_messages[lang].merge!(contents)
            else
              preprocessed_messages[lang] = contents
            end
          else
            if preprocessed_messages.has_key?(name)
              preprocessed_messages[name].merge!(contents)
            else
              preprocessed_messages[name] = contents
            end
          end
        end

        # Create catalogue from preprocessed messages
        locale_catalogues = {} of String => Catalogue
        preprocessed_messages.each do |name, translations|
          catalogue = Catalogue.new(translations)
          if (lang = catalogue.headers["Language"]?) && (!lang.empty?)
            locale_catalogues[lang] = catalogue
          else
            locale_catalogues[name] = catalogue
          end
        end

        return locale_catalogues
      end
    end

    abstract def parse
    private abstract def parse_(file_name, io : IO)

    private def extract_headers(contents)
      headers = {} of String => String

      header_fields = [] of String
      contents[""]?.try &.[0].split("\n") { |v| header_fields << v if !v.empty? } || nil

      header_fields.each do |h|
        header = h.split(":", limit: 2)
        next if header.size <= 1
        headers[header[0]] = header[1].strip
      end

      return headers
    end
  end

  # Gettext message catalogue. Contains methods for handling translations
  #
  # You **should not** be manually creating an instance of this class! Instead let the Gettext backends
  # do it for you! See `Gettext::MOBackend` and `Gettext::POBackend`
  struct Catalogue
    # Returns a hash of the headers
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en_US"]
    # catalogue.headers["Plural-Forms"] # => "nplurals=2; plural=(n != 1);"
    # ```
    getter headers : Hash(String, String)
    @plural_interpreter : PluralForm::Interpreter?

    # Returns all messages within the catalogue
    #
    # You should **never** have to deal with this method under normal circumstances.
    # Please use the `#gettext` family of methods to translate your application instead.
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en-US"]
    # catalogue.contents # => {...}
    # ```
    getter contents : Hash(String, Hash(Int8, String))

    # Creates a message catalogue from parsed Gettext data
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
        expressions = Gettext::PluralForm::Parser.new(plural_form_expression).parse
        @plural_interpreter = Gettext::PluralForm::Interpreter.new(expressions)
      else
        @plural_interpreter = nil
      end
    end

    private def process_plural(n)
      return @plural_interpreter.not_nil!.interpret(n)
    end

    # Fetches the translated message for the specific ID. If none can be found the given ID is returned.
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en_US"]
    # catalogue.gettext("A message")     # => "Translated message"
    # catalogue.gettext("I don't exist") # => "I don't exist"
    # ```
    def gettext(id : String)
      begin
        return @contents[id][0]
      rescue KeyError
        return id
      end
    end

    # Fetches the translated message for the specific ID with the correct plural form. Returns either the singular or plural id if none can be found.
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en_US"]
    # catalogue.ngettext("I have %d apple", "I have %d apples", 0) # => "Translated message with plural-form 1"
    # catalogue.ngettext("I have %d apple", "I have %d apples", 1) # => "Translated message with plural-form 0"
    #
    # # Not found:
    # catalogue.ngettext("I have %d pear", "I have %d pears", 0) # => "I have %d pears"
    # catalogue.ngettext("I have %d pear", "I have %d pears", 1) # => "I have %d pear"
    # ```
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
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en_US"]
    #
    # catalogue.pgettext("CopyPasteMenu", "copy")          # => "Translated copy"
    # catalogue.pgettext("CopyPasteMenu", "I don't exist") # => "I don't exist"
    # ```
    def pgettext(context, id)
      begin
        return @contents["#{context}\u0004#{id}"][0]
      rescue KeyError
        return id
      end
    end

    # Fetches the translated message for the specific ID that is bound by context with the correct plural form.
    #
    # ```
    # catalogue = Gettext::MOBackend.new("examples").create["en_US"]
    # catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 0) # => "Translated message with plural-form 1"
    # catalogue.npgettext("CopyPasteMenu", "Export %d file", "Export %d files", 1) # => "Translated message with plural-form 0"
    #
    # # Not found:
    # catalogue.npgettext("CopyPasteMenu", "None", "NonePlural", 0) # => "NonePlural"
    # catalogue.npgettext("CopyPasteMenu", "None", "NonePlural", 1) # => "None"
    # ```
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
