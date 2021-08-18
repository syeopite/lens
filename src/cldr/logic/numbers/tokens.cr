module CLDR::Numbers
  private enum TokenTypes
    DigitPlaceholder                 # 0
    RoundingSignifier                # 1-9
    SignificantDigitSignifier        # @
    DigitPlaceholderNoFrontBackZeros # #
    DecimalSeparator                 # .
    MinusSign                        # -
    GroupingSeparator                # ,
    ExponentialSeparator             # E
    PlusSign                         # +
    PercentSign                      # %
    PerMilleSign                     # ‰
    SubPatternBoundary               # ;
    CurrencySymbol                   # ¤
    PaddingSignifier                 # *
    StringLiteral                    # 'x'

    Character # Any

    DUMMY
    EOF
  end

  # Object representing a token from the grammar of CLDR number patterns
  struct Token
    getter literal : (String | Int32)?
    getter column : Int32 | Int64
    getter token_type : TokenTypes

    def initialize(@token_type, @literal, @column)
    end
  end
end
