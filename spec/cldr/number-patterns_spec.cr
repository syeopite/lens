require "digest"
require "../../src/cldr/logic/numbers/lexer"
require "../../src/cldr/logic/numbers/parser"
require "../../src/cldr/logic/numbers/formatter"
require "../../src/cldr/languages/en/*"

describe CLDR::Numbers::PatternLexer do
  it "Can scan pattern #,##0.##" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("#,##0.##").scan.to_s).should(eq("8e1924de25f4aea2eaff8e167ab1daee7f7bbf31beaefd25421153f924a00277"))
  end

  it "Can scan pattern 0.00+;0.00-" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("0.00+;0.00-").scan.to_s).should(eq("b9e260de6663502182fda3a8db754f674107a6b941384c2039e5c0699cb45e6b"))
  end

  it "Can scan pattern ###0.0000#" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("###0.0000#").scan.to_s).should(eq("ae321d5d14359b8e5fc5c5b7ebbe7e0cd0565763238a8840fe5369d389921dd8"))
  end

  it "Can scan pattern 00000.0000" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("00000.0000").scan.to_s).should(eq("1896b5b093760d98ef7e53281b8e28c716a90912eab95405ac2cba81a29649dc"))
  end

  it "Can scan pattern #,##0.00 ¤" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("#,##0.00 ¤").scan.to_s).should(eq("7f598410dfba37878b80c46e141bac48f4918511996a92fd7a10fc4735a0f229"))
  end
end

describe CLDR::Numbers::PatternParser do
  it "Can parse pattern: '#,##0.##'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=false),
    # CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    # CLDR::Numbers::Rules::Fractional( @leading_zeros=false,@size=2, @trailing_zeros=false)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("95400605930b4bf3b9486fea9bcf00bbc1925298cee6798b8872e42aec657e5d"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  # it "Can parse pattern: '0.00+;0.00-'" do
  #   rules, metadata = CLDR::Numbers::PatternParser.new("0.00+;0.00-").parse
  # end

  it "Can parse pattern: '###0.0000#'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("###0.0000#").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=true),
    # CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    # CLDR::Numbers::Rules::Fractional( @leading_zeros=true, @size=5, @trailing_zeros=false)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("9133e83847ad12fd2015976ba1c2c85efe16b65bda6b1858d76d62c689800442"))

    metadata.primary_grouping.should(eq(nil))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '00000.0000'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("00000.0000").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=true, @trailing_zeros=true),
    #  CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    #  CLDR::Numbers::Rules::Fractional(@leading_zeros=true, @size=4,@trailing_zeros=true)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("aece7bbf7cb909757b6c8a46c83095b26bed089896ef08576a47ef276e856a38"))

    metadata.primary_grouping.should(eq(nil))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '#,##0.00 ¤'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.00 ¤").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=true),
    # CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    # CLDR::Numbers::Rules::Fractional(
    #  @leading_zeros=true,
    #  @size=2,
    #  @trailing_zeros=false),
    # CLDR::Numbers::Rules::InjectCharacters(@character=" "),
    # CLDR::Numbers::Rules::InjectSymbol(@character=CurrencySymbol)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("c00ede9b9a017ab5c3f2bbe7607cd0240ac41e9203583aab4ec4929ff6d6979b"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '#,@@###,###.000'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,@@###,###").parse

    # CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=false)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("b4489f3618a51a2489ea0121d9ac4874977eb88290955505550ff549a4e74cf6"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(5))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(8))
    metadata.minimum_significant_figures.should(eq(2))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '@@##,###'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("@@###,###.###").parse

    # CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=false)
    Digest::SHA256.hexdigest(rules.to_s).should(eq("b1395beb8aa0973ee795ce6b1f1ef134a9f7046a998cfaa6c0e9fad002d52531"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(8))
    metadata.minimum_significant_figures.should(eq(2))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '#,###.0,##,0##'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,###.0,##,0##").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=false),
    # CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    # CLDR::Numbers::Rules::Fractional(
    #  @leading_zeros=true,
    #  @size=6,
    #  @trailing_zeros=false)]

    Digest::SHA256.hexdigest(rules.to_s).should(eq("da91a712e37dfa02eee3accce65c16da2026bbf3c3b5a12260ec030f578ffcfc"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(3))
    metadata.fractional_secondary_grouping.should(eq(2))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end
end
