require "yaml"
require "../../helpers/plural-rules/*"

# Namespace for logic relating to ruby-i18n's YAML format.
#
# This is a reimplementation of the ruby-i18n YAML format from [the ruby-i18n project](https://github.com/ruby-i18n/i18n).
#
# In crystal, this is often adapted into the crystal-i18n format seen in the following projects:
# * [TechMagister/i18n.cr](https://github.com/TechMagister/i18n)
# * [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
# * [crimson-knight/i18n.cr](https://github.com/crimson-knight/i18n.cr/)
#
# and any of the other implementations the community has made.
#
# Each of the variants in Crystal has some slight variations compared with the original ruby-i18n. Minor alternations are needed
# to be compatible with Lens. [See the usage documentation for more information](https://syeopite.github.io/lens/latest/formats/ruby-yaml/)
#
module RubyI18n
  # Backend for the ruby-i18n format. This class contains methods to parse and interact with them
  class Yaml
    # Creates a new ruby-i18n YAML instance that reads from the given locale directory path.
    #
    # ```
    # RubyI18n::Yaml.new("locales")
    # ```
    def initialize(locale_directory_path : String, reference_locale : String = "en")
      @_source = {} of String => Hash(String, YAML::Any)

      Dir.glob("#{locale_directory_path}/**/*.yml", "#{locale_directory_path}/**/*.yaml") do |yaml_file|
        begin
          contents = YAML.parse(File.read(yaml_file)).as_h
        rescue YAML::ParseException
          raise LensExceptions::ParseError.new("Invalid yaml file detected when parsing for ruby-i18n's YAML format. " + \
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

        contents.each do |language_key, translation|
          if @_source[language_key.as_s]?
            @_source[language_key.as_s].merge!(stringify_keys(translation.as_h))
          else
            @_source[language_key.as_s] = stringify_keys(translation.as_h)
          end
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
    # catalogue = RubyI18n::Yaml.new("locales")
    #
    # catalogue.select("en")
    # catalogue.translate("translation") # => "Translated Message"
    #
    # catalogue.select("example")
    # catalogue.translate("translation") # => "Some message in another language"
    #
    # catalogue.select("doesn't exist") # raises KeyError
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
    # Functionality is the same as `RubyI18n::Yaml.translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil)`
    # but with the first argument removed
    def translate(key : String, count : Int | Float? = nil, iter : Int? = nil, scope : (Indexable(String) | String)? = nil, **kwargs)
      self.translate(@lang_state, key, count, iter, scope, **kwargs)
    end

    # Fetches a translation from the *given* locale with the given path (key).
    #
    # Basic usage is this:
    # ```
    # catalogue = RubyI18n::Yaml.new("locales")
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
    # A scope, the area from which the key-path should traverse from, can also be specified. For instance, a scope of `possessions.fruits`
    # would allow the key to just be `apples`.
    # ```
    # catalogue.translate("en", "possessions", 1, scope : {"possessions", "fruits"})  # => "I have 1 apple"
    #
    # # Strings also work!
    # catalogue.translate("en", "possessions", 1, scope : "possessions.fruits")  # => "I have 1 apple"
    # ```
    #
    # When a translation is not found `LensExceptions::MissingTranslation` would be raised.
    #
    def translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil, scope : (Indexable(String) | String)? = nil, **kwargs)
      self.internal_translate(locale, key, count, iter, scope, **kwargs)
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

    # Localize a date object with correspondence to a specific format.
    #
    # Raises `LensExceptions::MissingTranslation` when the selected format doesn't exist.
    #
    # NOTE: Default data is provided for the English locale.
    #
    # ```
    # date = Time.unix(1629520612)
    # catalogue.localize("en", date, format: "default") # => "2021-08-21"
    # catalogue.localize("en", date, format: "long")    # => "July 21, 2021"
    # catalogue.localize("en", date, format: "short")   # => "Jul 21"
    #
    # # Raises when the given format isn't defined.
    # catalogue.localize("ru", date, format: "short") # LensExceptions::MissingTranslation
    # ```
    #
    def localize(locale : String, time : Time, format : String)
      pattern = @_source[locale].dig?("date", "formats", format)

      if pattern.nil?
        if locale == "en"
          pattern = case format
                    when "default" then "%Y-%m-%d"
                    when "short"   then "%b %d"
                    when "long"    then "%B %d, %Y"
                    end
        else
          raise LensExceptions::MissingTranslation.new("The selected format: '#{format}' for time localization, does not exist!")
        end
      else
        pattern = pattern.as_s
      end

      return self.internal_localize_time(locale, pattern.as(String), time)
    end

    # Localize a number with correspondence to a specific type.
    #
    # Raises `LensExceptions::MissingTranslation` when attributes required for formatting are missing. [See usage docs for more information]()
    #
    # Currently, Lens supports 3 localization types for numbers, within the ruby-i18n YAML format.
    #
    # * Humanize
    # * Percentage
    # * Currency
    #
    # Two different formats are available in humanize.
    # - Bytes
    #    - Provides humanized byte size. IE 100000 bytes -> 1 MB
    # - Decimal
    #    - Provides humanized positive numbers.
    #
    # NOTE: Default data is provided for the English locale.
    #
    #
    # The most basic usage is humanizing a number. For instance:
    # ```
    # catalogue.localize("en", 1000)           # => "1 Thousand"
    # catalogue.localize("en", 10_250_000_000) # => "10.2 Billion"
    # ```
    #
    # Humanized bytes:
    # ```
    # catalogue.localize("en", 1000, type: "humanize", format: "storage_units" # => "1 KB"
    # catalogue.localize("en", 1500, type: "humanize", format: "storage") # => "1.5 KB"
    #
    # catalogue.localize("en", 100_000, type: "humanize", format: "bytes") # => "100 KB"
    # catalogue.localize("en", 120_000, type: "humanize", format: "storage") # => "120 KB"
    # catalogue.localize("en", 102_000, type: "humanize", format: "storage") # => "102 KB"
    # ```
    #
    # Localized percentages:
    # ```
    # catalogue.localize("en", 4.528, type: "percentage").should eq("4.53%")
    # ```
    #
    # Localized currency:
    # ```
    # catalogue.localize("en", 4.528, type: "currency").should eq("$4.528")
    # ```
    #
    # [For a more detailed explanation, please refer to the usage documentation.](https://syeopite.github.io/lens/latest/formats/ruby-yaml/)
    #
    #
    def localize(locale : String, number : Int32 | Int64 | Float64,
                 type : String = "humanize", format : String? = nil)
      case type.downcase
      when "human", "humanize"
        self.internal_localize_human(locale, number, format || "decimal_units")
      when "percentage", "percent"
        self.internal_localize_percentage(locale, number)
      when "currency", "money"
        self.internal_localize_currency(locale, number)
      else
        self.internal_localize_human(locale, number, format || "decimal_units")
      end
    end

    # Retrieves format properties for the given format type
    private def get_properties_for_format_type(locale : String, type : String)
      default_number_properties = @_source[locale].dig?("number", "format").try &.as_h
      properties_for_type = @_source[locale].dig?("number", type, "format").try &.as_h

      if !default_number_properties
        default_number_properties = {} of (YAML::Any | String) => YAML::Any
      end

      if properties_for_type
        properties = default_number_properties.merge(properties_for_type)
      else
        properties = {} of (YAML::Any | String) => YAML::Any
      end

      # Default values
      if locale == "en"
        properties = stringify_keys(properties)
        properties.["separator"] ||= YAML::Any.new(CLDR::Languages::EN::DecimalSymbol)
        properties.["delimiter"] ||= YAML::Any.new(CLDR::Languages::EN::GroupSymbol)

        # The following is all typically denoted by the pattern but since we
        # can't use that we'll just hardcode them.
        properties.["precision"] ||= YAML::Any.new(3_i64)
        properties.["significant"] ||= YAML::Any.new(false)
        properties.["strip_insignificant_zeros"] ||= YAML::Any.new(false)
      end

      return properties
    end

    # Set pluralization rules for the given locale.
    # See `RubyI18n.define_rule` for more information
    def define_rule(locale : String, value : Int32 | Int64 | Float64 -> String)
      RubyI18n.define_rule(locale, value)
    end

    # Returns all defined CLDR plural rules.
    def plural_rules : Hash(String, Int32 | Int64 | Float64 -> String)
      return PluralRulesCollection::Rules
    end

    # Returns self | Here for compatibility with `Gettext::MOBackend` and `Gettext::POBackend`
    #
    # ```
    # catalogue = RubyI18n::Yaml.new("locales")
    # catalogue == catalogue.create # => true
    # ```
    #
    def create
      return self
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

    # Internal method for fetching and "decorating" translations.
    private def internal_translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil, scope : (Indexable(String) | String)? = nil, **kwargs)
      # Traversal through nested structure is done by stating paths separated by "."s
      keys = key.split(".")

      # However, if we've been given a scope then the selected keys should come after that.
      # Thus'll we'll append to scope data to the start of the keys array for digging.
      keys = case scope
             when Indexable(String) then scope + keys
             when String            then scope.split(".") + keys
             else                        keys
             end

      latch : YAML::Any? = nil
      keys.each_with_index do |k, i|
        if i == 0
          latch = @_source[locale][k]
        else
          latch = latch.not_nil![k]
        end
      end

      translation = latch.not_nil!

      if translation.as_a?
        if iter
          translation = translation[iter]
        else
          return translation.as_a
        end
      end

      if count
        plural_rule = PluralRulesCollection::Rules[locale].call(count)

        # If the translation is just a string instead of a hash then we'll
        # just ignore handling the plural forms for it.
        if translation.as_h?
          translation = translation[plural_rule].as_s.gsub("%{count}", count)
        else
          translation = translation.as_s
        end
      else
        translation = translation.as_s
      end

      # Handle interpolation
      kwargs.each do |k, v|
        translation = translation.gsub("%{#{k}}", v)
      end

      return translation
    end

    # Internal time localization method
    #
    # Format usage is almost equivalent to the typical time formatting operators, except the month and
    # day names are using their localized equivalents
    private def internal_localize_time(locale : String, format : String, time : Time)
      # Only the following are supported.
      # https://github.com/ruby-i18n/i18n/blob/0888807ab2fe4f4c8a4b780f5654a8175df61feb/lib/i18n/backend/base.rb#L260
      localized_format = format.gsub(/%(|\^)[aAbBpP]/) do |match|
        case match
        when "%a"  then self.translate(locale, "date.formats.abbr_day_names").as(Array(YAML::Any))[time.day_of_week.value % 7].as_s
        when "%^a" then self.translate(locale, "date.formats.abbr_day_names").as(Array(YAML::Any))[time.day_of_week.value % 7].as_s.upcase
        when "%A"  then self.translate(locale, "date.formats.day_names").as(Array(YAML::Any))[time.day_of_week.value % 7].as_s
        when "%^A" then self.translate(locale, "date.formats.day_names").as(Array(YAML::Any))[time.day_of_week.value % 7].as_s.upcase
        when "%b"  then self.translate(locale, "date.formats.abbr_month_names").as(Array(YAML::Any))[time.month - 1].as_s
        when "%^b" then self.translate(locale, "date.formats.abbr_month_names").as(Array(YAML::Any))[time.month - 1].as_s.upcase
        when "%B"  then self.translate(locale, "date.formats.month_names").as(Array(YAML::Any))[time.month - 1].as_s
        when "%^B" then self.translate(locale, "date.formats.month_names").as(Array(YAML::Any))[time.month - 1].as_s.upcase
        end
      end

      return Time::Format.new(localized_format).format(time)
    end

    # Internal number (humanize format) localization method.
    #
    # Transforms a number into the localized human readable variant. Supports special format types of bytes and decimal units.
    private def internal_localize_human(locale : String, number : Int32 | Int64 | Float64, format : String? = nil)
      properties = self.get_properties_for_format_type(locale, "human")

      if format
        # First we fetch the selected format and some default basic patterns
        format_pattern = case format.try &.downcase
                         when "storage_units", "storage", "bytes", "byte size"
                           selected_format = 1
                           attributes_for_format = @_source[locale].dig?("number", "human", "storage_units")
                           "%n %u"
                         when "decimal_units", "decimal", "", nil
                           selected_format = 2
                           attributes_for_format = @_source[locale].dig?("number", "human", "decimal_units")
                           "%n %u"
                         else
                           selected_format = 2
                           attributes_for_format = {} of (YAML::Any | String) => YAML::Any
                           nil
                         end

        if !attributes_for_format
          attributes_for_format = {} of (YAML::Any | String) => YAML::Any
        end

        format_pattern = attributes_for_format["format"]?.try &.as_s || format_pattern

        # Now we calculate the units
        unit = case selected_format
               when 1
                 exp = (Math.log(number.abs) / Math.log(1000)).to_i
                 # Reduce down to number of exp units.
                 number = number / (1000_i64 ** exp) if exp != 0

                 plural_rule = PluralRulesCollection::Rules[locale].call(number)

                 if locale == "en"
                   if !attributes_for_format["units"]?
                     exp = 5 if exp > 5
                     name = {"digital-byte", "digital-kilobyte", "digital-megabyte", "digital-gigabyte", "digital-terabyte", "digital-petabyte"}[exp]
                     CLDR::Languages::EN::Units::Short[name][plural_rule].lstrip("{0} ")
                   else
                     exp = 6 if exp > 6
                     key = {"byte", "kb", "mb", "gb", "tb", "pb", "eb"}[exp]
                     self.translate(locale, "number.human.storage_units.units.#{key}", count: number)
                   end
                 end
               when 2
                 exp = (number != 0 ? Math.log10(number.abs).floor : 0).to_i

                 # Assume that numbers are grouped into three (this isn't accurate but it seems to be what upstream does)
                 # and reduce to a multiple of it if it isn't.
                 #
                 # This is to allow numbers such as 100,000 to get interpreted as thousands.
                 if exp > 3 && exp % 3 != 0
                   while exp > 3 && exp % 3 != 0
                     exp -= 1
                   end
                 end

                 number = number / ("1#{"0" * exp}".to_i64) if exp != 0

                 # https://github.com/rails/rails/blob/f95c0b7e96eb36bc3efc0c5beffbb9e84ea664e4/activesupport/lib/active_support/number_helper/number_to_human_converter.rb#L51
                 if !attributes_for_format["units"]?
                   plural_rule = PluralRulesCollection::Rules[locale].call(number)
                   CLDR::Languages::EN::DecimalShortFormat["1#{"0"*exp}"][plural_rule].sub("00", " ")
                 else
                   # TODO refactor this
                   key = {a0: "unit", a1: "ten", a2: "hundred", a3: "thousand", a6: "million", a9: "billion", a12: "trillion", a15: "quadrillion"}["a#{exp}"]
                   self.translate(locale, "number.human.decimal_units.units.#{key}", count: number)
                 end
               end
      end

      formatted = number.humanize(
        precision: properties["precision"].as_i,
        separator: properties["separator"].as_s,
        delimiter: properties["delimiter"].as_s,
        significant: properties["significant"].as_bool,
        prefixes: { {'\0'}, {'\0'} }
      ).rstrip('\0')

      if properties["strip_insignificant_zeros"]
        escaped_separator = Regex.escape(properties["separator"].as_s)
        formatted = formatted.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, "")
      end

      if format && format_pattern
        formatted = format_pattern.gsub("%n", formatted).gsub("%u", unit)
      end

      return formatted
    rescue KeyError
      if selected_format == 0
        format = "bytes"
      elsif selected_format = 1
        format = "decimals"
      end

      raise LensExceptions::MissingTranslation.new("Unable to locate the formatting information required for humanizing **#{format}**. " \
                                                   "\nPlease check the '#{locale}' locale and make sure it's defined in there.")
    end

    # Internal number (percentage) localization method.
    #
    # Transforms a number into a localized human-readable percentage.
    private def internal_localize_percentage(locale : String, number : Int32 | Int64 | Float64)
      properties = self.get_properties_for_format_type(locale, "percentage")
      format_pattern = @_source[locale].dig?("number", "percentage", "format", "format").try &.as_s || nil

      if format_pattern.nil?
        if locale == "en"
          format_pattern = "%n%"
        else
          raise LensExceptions::MissingTranslation.new("Missing pattern for localizing percentages in locale '#{locale}'!")
        end
      end

      formatted = number.humanize(
        precision: properties["precision"].as_i,
        separator: properties["separator"].as_s,
        delimiter: properties["delimiter"].as_s,
        significant: properties["significant"].as_bool,
        prefixes: { {'\0'}, {'\0'} }
      ).rstrip('\0')

      if properties["strip_insignificant_zeros"]
        escaped_separator = Regex.escape(properties["separator"].as_s)
        formatted = formatted.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, "")
      end

      formatted = format_pattern.gsub("%n", formatted)
      if 0 < number < 1
        return "0#{properties["separator"]}#{formatted}"
      else
        formatted
      end
    rescue KeyError
      raise LensExceptions::MissingTranslation.new("Unable to locate the formatting information required for localizing a **percentage**. " \
                                                   "\nPlease check the '#{locale}' locale and make sure it's defined in there.")
    end

    # Internal number (currency) localization method.
    #
    # Transforms a currency into a localized human-readable currency amount expression.
    private def internal_localize_currency(locale : String, number : Int32 | Int64 | Float64)
      properties = self.get_properties_for_format_type(locale, "currency")
      format_pattern = @_source[locale].dig?("number", "currency", "format", "format").try &.as_s

      if format_pattern.nil?
        if locale == "en"
          format_pattern = "%u%n"
        else
          raise LensExceptions::MissingTranslation.new("Missing pattern for localizing currency in locale '#{locale}'!")
        end
      end

      unit = @_source[locale].dig?("number", "percentage", "format", "unit").try &.as_s
      if !unit
        if locale == "en"
          unit = '$'
        else
          raise LensExceptions::MissingTranslation.new("Missing currency symbol for localizing currency in locale '#{locale}'!")
        end
      end

      formatted = number.humanize(
        precision: properties["precision"].as_i,
        separator: properties["separator"].as_s,
        delimiter: properties["delimiter"].as_s,
        significant: properties["significant"].as_bool,
        prefixes: { {'\0'}, {'\0'} }
      ).rstrip('\0')

      if properties["strip_insignificant_zeros"]
        escaped_separator = Regex.escape(properties["separator"].as_s)
        formatted = formatted.sub(/(#{escaped_separator})(\d*[1-9])?0+\z/, "")
      end

      if 0 < number < 1
        formatted = "0#{properties["separator"]}#{formatted}"
        format_pattern.gsub("%n", formatted).gsub("%u", unit)
      elsif -1 < number < 0
        formatted = formatted.lstrip('-')
        formatted = "0#{properties["separator"]}#{formatted}"
        return "-#{format_pattern.gsub("%n", formatted).gsub("%u", unit)}"
      else
        return format_pattern.gsub("%n", formatted).gsub("%u", unit)
      end
    rescue KeyError
      raise LensExceptions::MissingTranslation.new("Unable to locate the formatting information required for localizing **currencies**. " \
                                                   "\nPlease check the '#{locale}' locale and make sure it's defined in there.")
    end
  end

  # Set pluralization rules for the given locale
  #
  # This allows you to overwrite or even define new pluralization rules
  # for whatever locale you desire.
  #
  # ```
  # RubyI18n.define_rule("ar", ->(n : Int32 | Int64 | Float64) {
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
