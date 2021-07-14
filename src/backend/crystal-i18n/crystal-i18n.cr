require "yaml"
require "../../helpers/plural-rules/*"

# Namespace for logic relating to the crystal-i18n format.
#
# This is a reimplementation of the crystal-i18n format from the following projects:
# * [TechMagister/i18n.cr](https://github.com/TechMagister/i18n)
# * [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
# * [mattetti/i18n](https://github.com/mattetti/i18n)
#
# and any of the other similar implementations the community has made.
#
# Note that this is still experimental, mainly in regards to plural-forms. Other than that, it should be
# fully usable and accurate.
#
@[Experimental]
module CrystalI18n
  # Backend for the crystal-i18n format. This class contains methods to parse and interact with them
  #
  # Note that this is still experimental, mainly in regards to plural-forms. Other than that, it should be
  # fully usable and accurate.
  #
  # TODO: write usage documentation
  @[Experimental]
  class I18n
    # Creates a new crystal-i18n instance that reads from the given locale directory path.
    #
    # ```
    # CrystalI18n::I18n.new("locales")
    # ```
    def initialize(locale_directory_path : String, reference_locale : String = "en")
      @_source = {} of String => Hash(String, YAML::Any)

      Dir.glob("#{locale_directory_path}/*.yml") do |yaml_file|
        name = File.basename(yaml_file, ".yml")
        begin
          contents = YAML.parse(File.read(yaml_file)).as_h
        rescue YAML::ParseException
          raise LensExceptions::ParseError.new("Invalid yaml file detected when parsing for the crystal-i18n format. " + \
            "Please make sure that the file: '#{locale_directory_path}/#{yaml_file}' " + \
              "is formatted correctly")
        end

        if @_source[name]?
          @_source[name].merge!(stringify_keys(contents))
        else
          @_source[name] = stringify_keys(contents)
        end
      end

      @lang_state = reference_locale
    end

    # Fetches a translation from the selected locale with the given path (key).
    #
    # Basic usage is this:
    # ```
    # catalogue = CrystalI18n::I18n.new("locales")
    # catalogue.translate("en", "translation") # => "Translated Message"
    # ```
    #
    # This method can also translate plural-forms through the count argument.
    # ```
    # catalogue.translate("en", "processions.fruits.apples", 50) # => "I have 50 apples"
    # catalogue.translate("en", "processions.fruits.apples", 1)  # => "I have 1 apple"
    # ```
    #
    # Interpolation can be done through kwargs.
    # ```
    # # message is 'Hello there, my name is %{name} and I'm a %{profession}`.
    # result = catalogue.translate("en", "introduction.messages", name: "Steve", profession: "programmer")
    # result # => "Hello there, my name is Steve and I'm a programmer"
    # ```
    #
    # When a translation is not found `LensExceptions::MissingTranslation` would be raised.
    #
    def translate(locale : String, key : String, count : Int | Float? = nil, **kwargs)
      self.internal_translate(locale, key, count, **kwargs)
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
    def plural_rules(locale : String, value : Int32 | Int64 | Float64 -> String)
      CrystalI18n.define_rule(locale, value)
    end

    # Internal method for fetching and "decorating" translations.
    private def internal_translate(locale : String, key : String, count : Int | Float? = nil, **kwargs)
      # Traversal through nested structure is done by stating paths separated by "."s
      keys = key.split(".")
      translation = @_source[locale].dig(keys[0], keys[1..])

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
