require "digest"
require "../../src/cldr/logic/numbers/lexer"
require "../../src/cldr/logic/numbers/parser"
require "../../src/cldr/logic/numbers/formatter"
require "../../src/cldr/languages/en/*"

describe CLDR::Numbers::PatternLexer do
  it "Can scan pattern A" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("#,##0.##").scan.to_s).should(eq("8e1924de25f4aea2eaff8e167ab1daee7f7bbf31beaefd25421153f924a00277"))
  end

  it "Can scan pattern B" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("0.00+;0.00-").scan.to_s).should(eq("b9e260de6663502182fda3a8db754f674107a6b941384c2039e5c0699cb45e6b"))
  end

  it "Can scan pattern C" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("###0.0000#").scan.to_s).should(eq("ae321d5d14359b8e5fc5c5b7ebbe7e0cd0565763238a8840fe5369d389921dd8"))
  end

  it "Can scan pattern D" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("00000.0000").scan.to_s).should(eq("1896b5b093760d98ef7e53281b8e28c716a90912eab95405ac2cba81a29649dc"))
  end

  it "Can scan pattern E" do
    Digest::SHA256.hexdigest(CLDR::Numbers::PatternLexer.new("#,##0.00 ¤").scan.to_s).should(eq("7f598410dfba37878b80c46e141bac48f4918511996a92fd7a10fc4735a0f229"))
  end
end

describe CLDR::Numbers::PatternParser do
  it "Can parse pattern: '#,##0.##'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse

    # [CLDR::Numbers::Rules::Integer(@leading_zeros=false, @trailing_zeros=false),
    # CLDR::Numbers::Rules::InjectSymbol(@character=DecimalSeparator),
    # CLDR::Numbers::Rules::Fractional( @leading_zeros=false,@size=2, @trailing_zeros=false)]
    Digest::SHA256.hexdigest(rules.to_s).should(eq("85060283cc519b96e8568228e716dd8702ebd01a4cfb5ce1085759c3656fc9d6"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("9daebf03f8156e59b2d681aae4b4c818eed4da0013c8a54d275c6efa4399018f"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("f12ed58a6bfbe4bdb2dad4a49d5807ad52c01ec301f7607c07808b08c3f1f78e"))

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

    Digest::SHA256.hexdigest(rules.to_s).should(eq("d00810e4b7571d39caf9ee999dcad81dc00ded30744af15ab941fb86cc054096"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("cda3a37489e10497a6a7e9c0fa9a1ad6b794c510cfc56ebf9852246331575fe7"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("5c42c6ea3739a793c784a8145a21998fa90ea0cf7e06790fd79dae08d18fb880"))

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

    Digest::SHA256.hexdigest(rules.to_s).should(eq("72a345f805cf0843558fa07e4ac2321e0d3826ce77743e0dafbfefbb97976f79"))

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
