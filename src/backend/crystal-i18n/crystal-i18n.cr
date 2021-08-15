require "yaml"
require "../../helpers/plural-rules/*"

# Namespace for logic relating to the crystal-i18n format.
#
# This is a reimplementation of the crystal-i18n format from the following projects:
# * [TechMagister/i18n.cr](https://github.com/TechMagister/i18n)
# * [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
#
# and any of the other similar implementations the community has made.
#
module CrystalI18n
  # Backend for the crystal-i18n format. This class contains methods to parse and interact with them
  class I18n
    # Creates a new crystal-i18n instance that reads from the given locale directory path.
    #
    # ```
    # CrystalI18n::I18n.new("locales")
    # ```
    def initialize(locale_directory_path : String, reference_locale : String = "en")
      @_source = {} of String => Hash(String, YAML::Any)

      Dir.glob("#{locale_directory_path}/**/*.yml") do |yaml_file|
        name = File.basename(yaml_file, ".yml")
        begin
          contents = YAML.parse(File.read(yaml_file)).as_h
        rescue YAML::ParseException
          raise LensExceptions::ParseError.new("Invalid yaml file detected when parsing for the crystal-i18n format. " + \
            "Please make sure that the file: '#{yaml_file}' " + \
              "is formatted correctly")
        rescue ex
          case ex.message
          # If a directory has a .yml suffix we'll just ignore it.
          when "Error reading file: Is a directory"
            next
          else
            raise ex
          end
        end

        if @_source[name]?
          @_source[name].merge!(stringify_keys(contents))
        else
          @_source[name] = stringify_keys(contents)
        end
      end

      @lang_state = reference_locale
    end

    # Selects a locale to use for translations
    #
    # Raises a KeyError when the selected locale isn't found.
    #
    # If your application is monolingual then this along with `#translate(key, count, iter)` is your friend.
    # However, if you need to switch languages on the fly then this method should be ignored.
    #
    # Instead, you should use the `#translate(locale, key, count, iter)` overload, which allows for fetching
    # messages from any locales without changing the state of the instance.
    #
    # ```
    # catalogue = CrystalI18n::I18n.new("locales")
    #
    # catalogue.select("en")
    # catalogue.translate("translation") # => "Translated Message"
    #
    # catalogue.select("example")
    # catalogue.translate("translation") # => "Some message in another language"
    #
    # catalogue.select("doesn'texist")
    # catalogue.translate("translation") # => "Some message in another language"
    # ```
    #
    def select(locale)
      if @_source.has_key?(locale)
        @lang_state = locale
      else
        raise KeyError.new("The #{locale} doesn't exist")
      end
    end

    # Fetches a translation from the *selected* locale with the given path (key).
    #
    # Functionality is the same as `CrystalI18n::I18n.translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil)`
    # but with the first argument removed
    def translate(key : String, count : Int | Float? = nil, iter : Int? = nil, **kwargs)
      self.translate(@lang_state, key, count, iter, **kwargs)
    end

    # Fetches a translation from the *given* locale with the given path (key).
    #
    # Basic usage is this:
    # ```
    # catalogue = CrystalI18n::I18n.new("locales")
    # catalogue.translate("en", "translation") # => "Translated Message"
    # ```
    #
    # This method can also translate plural-forms through the count argument.
    # ```
    # catalogue.translate("en", "possessions.fruits.apples", 50) # => "I have 50 apples"
    # catalogue.translate("en", "possessions.fruits.apples", 1)  # => "I have 1 apple"
    # ```
    #
    # Interpolation can be done through kwargs.
    # ```
    # # message is 'Hello there, my name is %{name} and I'm a %{profession}`.
    # result = catalogue.translate("en", "introduction.messages", name: "Steve", profession: "programmer")
    # result # => "Hello there, my name is Steve and I'm a programmer"
    # ```
    #
    # If the value at the given path (key) turns out to be an array then you can pass in the iter argument
    # to select a specific value at the given index
    # ```
    # catalogue.translate("en", "items.foods", iter: 2) # => "Hamburger"
    # ```
    #
    # When a translation is not found `LensExceptions::MissingTranslation` would be raised.
    #
    def translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil, **kwargs)
      self.internal_translate(locale, key, count, iter, **kwargs)
    rescue ex : KeyError | Exception
      if ex.is_a? KeyError
        raise LensExceptions::MissingTranslation.new("Translation in the path '#{key}' does not exist for #{locale} locale")
      elsif ex.message == "Expected Array or Hash, not String"
        raise LensExceptions::MissingTranslation.new("One of the routes given in the path: '#{key}' for the '#{locale}' locale leads to a dead end. " + \
          "Please make sure the path to the locale key is correct.")
      else
        raise ex
      end
    end

    # Set pluralization rules for the given locale.
    # See `CrystalI18n.define_rule` for more information
    def define_rule(locale : String, value : Int32 | Int64 | Float64 -> String)
      CrystalI18n.define_rule(locale, value)
    end

    # Returns all defined CLDR plural rules.
    def plural_rules : Hash(String, Int32 | Int64 | Float64 -> String)
      return PluralRulesCollection::Rules
    end

    # Returns self | Here for compatibility with `Gettext::MOBackend` and `Gettext::POBackend`
    #
    # catalogue = CrystalI18n::I18n.new("locales")
    # catalogue == catalogue.create() # => true
    def create
      return self
    end

    # Internal method for fetching and "decorating" translations.
    private def internal_translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil, **kwargs)
      # Traversal through nested structure is done by stating paths separated by "."s
      keys = key.split(".")
      if keys.size > 1
        translation = @_source[locale].dig(keys[0], keys[1..])
      else
        translation = @_source[locale][keys[0]]
      end

      if iter && translation.as_a?
        translation = translation[iter]
      end

      if count
        plural_rule = PluralRulesCollection::Rules[locale].call(count)
        translation = translation[plural_rule]

        translation = translation.as_s.gsub("%{count}", count)
      else
        translation = translation.as_s
      end

      # Handle interpolation
      kwargs.each do |k, v|
        translation = translation.gsub("%{#{k}}", v)
      end

      return translation
    end

    # Stringify all keys to allow for easy digging without type casting.
    private def stringify_keys(yaml_contents)
      output = {} of String => YAML::Any
      yaml_contents.each do |k, v|
        if nested_hash = v.as_h?
          # This should be refactored
          output[k.to_s] = YAML.parse(stringify_keys(nested_hash).to_yaml)
        else
          output[k.to_s] = v
        end
      end

      return output
    end
  end

  # Set pluralization rules for the given locale
  #
  # This allows you to overwrite or even define new pluralization rules
  # for whatever locale you desire.
  #
  # ```
  # CrystalI18n.define_rule("ar", ->(n : Int32 | Int64 | Float64) {
  #   case
  #   when n == 0             then "zero"
  #   when n == 1             then "one"
  #   when n == 2             then "two"
  #   when 3..10 === n % 100  then "few"
  #   when 11..99 === n % 100 then "many"
  #   else                         "other"
  #   end
  # })
  # ```
  def self.define_rule(locale : String, value : Int32 | Int64 | Float64 -> String)
    PluralRulesCollection::Rules[locale] = value
  end

  # Returns all defined CLDR plural rules
  def self.plural_rules : Hash(String, Int32 | Int64 | Float64 -> String)
    return PluralRulesCollection::Rules
  end
end
