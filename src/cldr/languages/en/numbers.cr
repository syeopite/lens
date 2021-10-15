module CLDR
  # :nodoc:
  module Languages
    module EN
      DecimalSymbol                = "."
      GroupSymbol                  = ","
      List                         = ";"
      PercentSignSymbol            = "%"
      PlusSignSymbol               = "+"
      MinusSignSymbol              = "-"
      ApproximatelySignSymbol      = "~"
      ExponentialSymbol            = "E"
      SuperscriptingExponentSymbol = "×"
      PerMilleSymbol               = "‰"
      Infinity                     = "∞"
      NanSymbol                    = "NaN"
      TimeSeparatorSymbol          = ":"

      MinimumGroupingDigits = 1

      StandardDecimalFormat = "#,##0.###"

      DecimalLongFormat = {
        "1000": {
          "one":   "0 thousand",
          "other": "0 thousand",
        },

        "10000": {
          "one":   "00 thousand",
          "other": "00 thousand",
        },

        "100000": {
          "one":   "000 thousand",
          "other": "000 thousand",
        },

        "1000000": {
          "one":   "0 million",
          "other": "0 million",
        },

        "10000000": {
          "one":   "00 million",
          "other": "00 million",
        },

        "100000000": {
          "one":   "000 million",
          "other": "000 million",
        },

        "1000000000": {
          "one":   "0 billion",
          "other": "0 billion",
        },

        "10000000000": {
          "one":   "00 billion",
          "other": "00 billion",
        },

        "100000000000": {
          "one":   "000 billion",
          "other": "000 billion",
        },

        "1000000000000": {
          "one":   "0 trillion",
          "other": "0 trillion",
        },

        "10000000000000": {
          "one":   "00 trillion",
          "other": "00 trillion",
        },

        "100000000000000": {
          "one":   "000 trillion",
          "other": "000 trillion",
        },
      }

      DecimalShortFormat = {
        "1000": {
          "one":   "0K",
          "other": "0K",
        },

        "10000": {
          "one":   "00K",
          "other": "00K",
        },

        "100000": {
          "one":   "000K",
          "other": "000K",
        },

        "1000000": {
          "one":   "0M",
          "other": "0M",
        },

        "10000000": {
          "one":   "00M",
          "other": "00M",
        },

        "100000000": {
          "one":   "000M",
          "other": "000M",
        },

        "1000000000": {
          "one":   "0B",
          "other": "0B",
        },

        "10000000000": {
          "one":   "00B",
          "other": "00B",
        },

        "100000000000": {
          "one":   "000B",
          "other": "000B",
        },

        "1000000000000": {
          "one":   "0T",
          "other": "0T",
        },

        "10000000000000": {
          "one":   "00T",
          "other": "00T",
        },

        "100000000000000": {
          "one":   "000T",
          "other": "000T",
        },
      }

      ScientificFormat = "#E0"
      PercentFormat    = "#,##0%"
      # CurrencyFormat = {}
    end
  end
end
