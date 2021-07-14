require "./backend/*"

module Lens
  VERSION = "0.1.0"

  # List of supported formats within lens.
  #
  # For their respective documentations see:
  # `Gettext::POBackend`
  # `Gettext::MOBackend`
  # `CrystalI18n::I18n`
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
  # Lens.fetch_backend(Lens::Formats::GettextPO)       # => Gettext::POBackend
  # Lens.fetch_backend(Lens::Formats::GettextMO)       # => Gettext::MOBackend
  # Lens.fetch_backend(Lens::Formats::CrystalI18nYAML) # => CrystalI18n::I18n
  # ```
  def fetch_backend(fmt : Formats)
    case fmt
    when GettextPO       then Gettext::POBackend
    when GettextMO       then Gettext::MOBackend
    when CrystalI18nYAML then CrystalI18n::I18n
    end
  end
end
