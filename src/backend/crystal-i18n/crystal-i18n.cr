require "yaml"
require "../../helpers/plural-rules/*"

# Namespace for logic relating to the crystal-i18n format.
#
# This is a reimplementation of the crystal-i18n format, which is inspired by ruby-i18n,
# from the following projects:
# * [TechMagister/i18n.cr](https://github.com/TechMagister/i18n)
# * [crystal-i18n/i18n](https://github.com/crystal-i18n/i18n)
#
# and all of the other implementations of crystal-i18n the community has made.
#
# Note that this is still experimental, mainly in regards to plural-forms. Other than that, it should be
# fully usable and accurate.
#
# TODO: write usage documentation
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
    def initialize(locale_directory_path : String, reference_locale : String = "en")
      @_source = {} of String => Hash(String, YAML::Any)

      Dir.glob("#{locale_directory_path}/*.yml") do |yaml_file|
        name = File.basename(yaml_file, ".yml")
        begin
          contents = YAML.parse(File.read(yaml_file)).as_h
        rescue YAML::ParseException
          raise LensExceptions::ParseError.new("Invalid yaml file: #{yaml_file} for crystal-i18n format")
        end

        if @_source[name]?
          @_source[name].merge!(stringify_keys(contents))
        else
          @_source[name] = stringify_keys(contents)
        end
      end

      @lang_state = reference_locale
    end

    def translate(locale : String, key : String, count : Int | Float? = nil, **kwargs)
      puts kwargs
      self.internal_translate(locale, key, count, **kwargs)
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
end
