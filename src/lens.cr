require "./backend/**"

module Lens
  VERSION = "0.1.0"

  # List of supported formats within lens.
  #
  # For their respective documentations see:
  # `Gettext::POBackend`
  # `Gettext::MOBackend`
  # `CrystalI18n::I18n`
  #
  @[Deprecated("Please just call the respective backends instead of using this enum!")]
  enum Formats
    GettextPO
    GettextMO
    CrystalI18nYAML
  end

  # Returns the backend for the selected format
  #
  # Please note that each backend has a different API for translations.
  #
  # ```
  # require "lens"
  #
  # Lens.fetch_backend(Lens::Formats::GettextPO).as(Gettext::POBackend.class)      # => Gettext::POBackend
  # Lens.fetch_backend(Lens::Formats::GettextMO).as(Gettext::MOBackend.class)      # => Gettext::MOBackend
  # Lens.fetch_backend(Lens::Formats::CrystalI18nYAML).as(CrystalI18n::I18n.class) # => CrystalI18n::I18n
  # ```
  #
  @[Deprecated("Please just call the respective backends instead!")]
  def self.fetch_backend(fmt : Formats)
    case fmt
    when .gettext_po?        then Gettext::POBackend
    when .gettext_mo?        then Gettext::MOBackend
    when .crystal_i18n_yaml? then CrystalI18n::I18n
    end
  end
end
