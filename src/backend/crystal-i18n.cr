# Compiler doesn't give off warnings on deprecation to types
# See https://github.com/crystal-lang/crystal/issues/11043

@[Deprecated("CrystalI18n has been renamed to `RubyI18n` ")]
module CrystalI18n
  @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
  class I18n
    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def initialize(locale_directory_path : String, reference_locale : String = "en")
      @_source = {} of String => Hash(String, YAML::Any)

      Dir.glob("#{locale_directory_path}/**/*.yml") do |yaml_file|
        name = File.basename(yaml_file, ".yml")
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

        if @_source[name]?
          @_source[name].merge!(stringify_keys(contents))
        else
          @_source[name] = stringify_keys(contents)
        end
      end

      @lang_state = reference_locale
    end

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def select(locale)
      if @_source.has_key?(locale)
        @lang_state = locale
      else
        raise KeyError.new("The #{locale} doesn't exist")
      end
    end

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def translate(key : String, count : Int | Float? = nil, iter : Int? = nil, scope : (Indexable(String) | String)? = nil, **kwargs)
      self.translate(@lang_state, key, count, iter, scope, **kwargs)
    end

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def translate(locale : String, key : String, count : Int | Float? = nil, iter : Int? = nil, scope : (Indexable(String) | String)? = nil, **kwargs)
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

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def localize(locale : String, time : Time, format : String)
      format = @_source[locale].dig?("date", "formats", format)

      if !format
        raise LensExceptions::MissingTranslation.new("Missing format pattern: '#{format}', for time localization")
      end

      return self.internal_localize_time(locale, format, time)
    end

    # Internal time localization method
    #
    # Format usage is almost equivalent to the typical time formatting operators, except the month and
    # day names are using their localized equivalents
    private def internal_localize_time(locale : String, format : YAML::Any?, time : Time)
      # Only the following are supported.
      # https://github.com/ruby-i18n/i18n/blob/0888807ab2fe4f4c8a4b780f5654a8175df61feb/lib/i18n/backend/base.rb#L260
      localized_format = format.as_s.gsub(/%(|\^)[aAbBpP]/) do |match|
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

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def define_rule(locale : String, value : Int32 | Int64 | Float64 -> String)
      RubyI18n.define_rule(locale, value)
    end

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def plural_rules : Hash(String, Int32 | Int64 | Float64 -> String)
      return PluralRulesCollection::Rules
    end

    @[Deprecated("CrystalI18n::I18n has been renamed to `RubyI18n::Yaml` ")]
    def create
      return self
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

      if keys.size > 1
        translation = @_source[locale].dig(keys[0], keys[1..])
      else
        translation = @_source[locale][keys[0]]
      end

      if translation.as_a?
        if iter
          translation = translation[iter]
        else
          return translation.as_a
        end
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
end
