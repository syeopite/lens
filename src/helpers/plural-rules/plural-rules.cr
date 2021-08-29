# :nodoc:
# Module containing hard-codded plural rules based on CLDR
#
# NOTE: This will be replaced with a proper CLDR implementation that supports
# differing plural rules based on the shape of the floating point number too.
#
# This is mainly used for certain formats such as ruby-i18n YAML
module PluralRulesCollection
  # :nodoc:
  # Language code mapping to plural-rules
  # partially inspired by https://github.com/TechMagister/i18n.cr/blob/635e05dd5e9fb8bc99c46c12497689221644d9e4/src/i18n/config/plural_rules.cr
  # and all this here https://github.com/crystal-i18n/i18n/tree/fd818883b5a7acdd4983607690c2997b9e66dc2d/src/i18n/pluralization/rule
  Rules = {
    # First we'll get the languages with "unique" plural-rules out of the way.
    # Any plural-forms that are repeated, such as in germanic languages, would get defined via macro below.
    "ar" => ->(n : Int32 | Int64 | Float64) {
      case
      when n == 0               then "zero"
      when n == 1               then "one"
      when n == 2               then "two"
      when (3..10) === n % 100  then "few"
      when (11..99) === n % 100 then "many"
      else                           "other"
      end
    },

    "br" => ->(n : Int32 | Int64 | Float64) {
      mod10 = n % 10
      mod100 = n % 100

      case
      when mod10 == 1 && !{11, 71, 91}.includes?(mod100) then "one"
      when mod10 == 2 && !{12, 72, 92}.includes?(mod100) then "two"
      when {3, 4, 9}.includes?(mod10) && (
        !(10..19).includes?(mod100) && \
           !(70..79).includes?(mod100) && \
             !(90..99).includes?(mod100)
      )
        "few"
      when n % 1000000 == 0 && n != 0 then "many"
      else                                 "other"
      end
    },

    "cy" => ->(n : Int32 | Int64 | Float64) {
      case n
      when 0 then "zero"
      when 1 then "one"
      when 2 then "two"
      when 3 then "few"
      when 6 then "many"
      else        "other"
      end
    },

    "ga" => ->(n : Int32 | Int64 | Float64) {
      case n
      when 1       then "one"
      when 2       then "two"
      when (3..6)  then "few"
      when (7..10) then "many"
      else              "other"
      end
    },

    "gd" => ->(n : Int32 | Int64 | Float64) {
      case n
      when 1, 11    then "one"
      when 2, 12    then "two"
      when (3..10)  then "few"
      when (13..19) then "few"
      else               "other"
      end
    },

    "gv" => ->(n : Int32 | Int64 | Float64) {
      case
      when {1, 2}.includes?(n % 10) || n % 20 == 0 then "one"
      else                                              "other"
      end
    },

    "hsb" => ->(n : Int32 | Int64 | Float64) {
      case n % 100
      when 1    then "one"
      when 2    then "two"
      when 3, 4 then "few"
      else           "other"
      end
    },

    "ksh" => ->(n : Int32 | Int64 | Float64) {
      case n
      when 0 then "zero"
      when 1 then "one"
      else        "other"
      end
    },

    "lag" => ->(n : Int32 | Int64 | Float64) {
      case
      when n == 0         then "zero"
      when n > 0 && n < 2 then "one"
      else                     "other"
      end
    },

    "lt" => ->(n : Int32 | Int64 | Float64) {
      mod10 = n % 10
      mod100 = n % 100

      case
      when (mod10 == 1) && (!(11..19).includes?(mod100))            then "one"
      when ((2..9).includes? mod10) && (!(11..19).includes? mod100) then "few"
      when n != 0                                                   then "many"
      else                                                               "other"
      end
    },

    "lv" => ->(n : Int32 | Int64 | Float64) {
      case
      when n != 0                       then "zero"
      when n % 10 == 1 && n % 100 != 11 then "one"
      else                                   "other"
      end
    },

    "mk" => ->(n : Int32 | Int64 | Float64) {
      case
      when n != 11 && n % 10 == 1 then "one"
      else                             "other"
      end
    },

    "mo" => ->(n : Int32 | Int64 | Float64) {
      case {n, n % 100}
      when {1, _}       then "one"
      when {0, (1..19)} then :fwe
      else                   "other"
      end
    },

    "mt" => ->(n : Int32 | Int64 | Float64) {
      case {n, n % 100}
      when {1, _}        then "one"
      when {0, (2..10)}  then "few"
      when {_, (11..19)} then "many"
      else                    "other"
      end
    },

    "pl" => ->(n : Int32 | Int64 | Float64) {
      mod10 = n % 10
      mod100 = n % 100

      case
      when n == 1                                                                    then "one"
      when {2, 3, 4}.includes?(mod10) && !{12, 13, 14}.includes?(mod100)             then "few"
      when ((0 <= mod10 <= 1) || (5..9) === mod10) || {12, 13, 14}.includes?(mod100) then "many"
      else                                                                                "other"
      end
    },

    "ro" => ->(n : Int32 | Int64 | Float64) {
      case {n, n % 100}
      when {1, _}       then "one"
      when {0, (1..19)} then "few"
      else                   "other"
      end
    },

    "sl" => ->(n : Int32 | Int64 | Float64) {
      case n % 100
      when 1    then "one"
      when 2    then "two"
      when 3, 4 then "few"
      else           "other"
      end
    },

    "tzm" => ->(n : Int32 | Int64 | Float64) {
      case
      when ((0 <= n <= 1) && (11..99) === n) then "one"
      else                                        "other"
      end
    },
  }

  # East slavic (I think) languages all have the same plural-forms so we're go ahead and define them via macro
  {% for lang_code in ["be", "by", "bs", "hr", "ru", "sh", "sr", "uk"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      # Pre calculate
      mod10 = n % 10
      mod100 = n % 100

      case
      when (mod10 == 1) && (mod100 != 11) then "one"
      when ((2..4) === mod10) && !((12..14) === mod100) then "few"
      when (mod10 == 0 ||(5..9) === mod10) || ((11..14) === mod100) then "many"
      else "other"
      end
    }
  {% end %}

  # West slavic (I think) languages all have the same plural-forms so we're go ahead and define them via macro
  {% for lang_code in ["sk", "cs"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      case n
      when 1 then "one"
      when (2..4) then "few"
      else "other"
      end
    }
  {% end %}

  # One Other
  {% for lang_code in ["de", "de-AT", "de-CH", "de-DE", "bg", "bn", "ca", "da", "dz", "el", "en-AU", "en-CA", "en-GB",
                       "en-IN", "en-NZ", "en", "eo", "es-419", "es-AR", "es-CL", "es-CO", "es-CR", "es-EC", "es-ES", "es-MX",
                       "es-NI", "es-PA", "es-PE", "es-US", "es-VE", "es", "et", "eu", "fi", "gl", "he", "hu", "it-CH", "is", "it",
                       "mn", "nb", "ne", "nl", "nn", "oc", "pt", "st", "sv-SE", "sv", "sw", "ur"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) { n == 1 ? "one" : "other"}
  {% end %}

  # One with zero other
  {% for lang_code in ["ak", "am", "bh", "guw", "hi-IN", "hi", "ln", "mg", "ml", "mr-IN", "nso", "or", "pa", "shi", "ti", "wa"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      n == 0 || n ==1 ? "one" : "other"
    }
  {% end %}

  # One two other
  {% for lang_code in ["iu", "naq", "se", "sma", "smi", "smj", "smn", "sms"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      case n
      when 1 then "one"
      when 2 then "two"
      else "other"
      end
    }
  {% end %}

  # OneUpToTwoOther
  {% for lang_code in ["ff", "fr-CA", "fr-CH", "fr-FR", "fr", "kab"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      n > 1 ? "other" : "one"
    }
  {% end %}

  # Other (Lack plural-forms)
  {% for lang_code in ["az", "bm", "bo", "dz", "fa", "id", "ig", "ii", "ja", "jv", "ka", "kde", "kea", "km", "kn", "ko", "lo", "ms", "my",
                       "pap-AW", "pap-CW", "root", "sah", "ses", "sg", "th", "to", "tr", "vi", "wo", "yo", "zh-CN", "zh-HK", "zh-TW", "zh-YUE",
                       "zh"] %}
    Rules[{{lang_code}}] = ->(n : Int32 | Int64 | Float64) {
      "other"
    }
  {% end %}
end
