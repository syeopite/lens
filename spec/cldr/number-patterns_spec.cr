require "digest"
require "../../src/cldr/logic/numbers/lexer"
require "../../src/cldr/logic/numbers/parser"
require "../../src/cldr/logic/numbers/formatter"
require "../../src/cldr/languages/en/numbers"

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("de87b782b6b35b38190e6db61c90fbf2b78c58ce913561d213d708d3fce60498"))

    metadata.primary_grouping.should(eq(3))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '0.00+;0.00-'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("0.00+;0.00-").parse
    Digest::SHA256.hexdigest(rules.to_s).should(eq("ae0155c50b2140c7da8d80d29c7c921dc732a67c4e39b702df0fab5e0ae86ca2"))

    metadata.primary_grouping.should(eq(nil))
    metadata.secondary_grouping.should(eq(nil))

    metadata.fractional_primary_grouping.should(eq(nil))
    metadata.fractional_secondary_grouping.should(eq(nil))

    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
  end

  it "Can parse pattern: '###0.0000#'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("###0.0000#").parse
    Digest::SHA256.hexdigest(rules.to_s).should(eq("e65f81767ac28642ff7fa4e56a166703640eeacf61c5ed386bc7cc68179107b5"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("b55e0e3d73a58c7814885ad9676b54f85ca8545f6e33711d7b0281b8a97b60df"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("b2a177c4caa0cbc035ba99e9a35e871ab4e96c1a9b5b8ce74bb322f70f6072b5"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("ac4f3b4b84d4201fa5bcdbbab5103eaa5cfc197e06ebe78acb5fc0c4c7b0b3f7"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("1b225792d2f470908492f3ea239de594753d1b301f2a33c7a522154579f026cc"))

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
    Digest::SHA256.hexdigest(rules.to_s).should(eq("5b60a2dab57d0d23844707b23dfe00ec840ffea1903a9eeb727e87889b08972e"))

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

describe CLDR::Numbers::PatternFormatter do
  it "Can format pattern: '#,##0.##'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(1000.1).should(eq("1,000.1"))
    formatter.format(-1000.1).should(eq("-1,000.1"))
    formatter.format(100000.1859).should(eq("100,000.19"))
    formatter.format(-100000.1859).should(eq("-100,000.19"))
  end

  it "Can format pattern: '0.00+;0.00-'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("0.00+;0.00-").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(1000.129).should(eq("1000.13+"))
    formatter.format(-1000.129).should(eq("1000.13-"))

    formatter.format(1000.1).should(eq("1000.10+"))
    formatter.format(-1000.1).should(eq("1000.10-"))

    formatter.format(100000.1859).should(eq("100000.19+"))
    formatter.format(-100000.1859).should(eq("100000.19-"))
  end

  it "Can format pattern: '###0.0000#'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("###0.0000#").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(1000.129).should(eq("1000.1290"))
    formatter.format(-1000.129).should(eq("-1000.1290"))

    formatter.format(1000.1).should(eq("1000.1000"))
    formatter.format(-1000.1).should(eq("-1000.1000"))

    formatter.format(1000.12345).should(eq("1000.12345"))
    formatter.format(-1000.12345).should(eq("-1000.12345"))
  end

  it "Can format pattern: '00000.0000'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("00000.0000").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(1000.123456).should(eq("1000.1235"))
    formatter.format(-1000.123456).should(eq("-1000.1235"))

    formatter.format(1000.129).should(eq("1000.1290"))
    formatter.format(-1000.129).should(eq("-1000.1290"))
  end

  # TODO
  # it "Can format pattern: '#,##0.00 ¤'" do
  # end

  # TODO
  # it "Can format pattern: '#,@@###,###.000'" do
  # end

  # TODO
  # it "Can format pattern: '@@##,###'" do
  # end

  it "Can format pattern: '#,###.0,##,0##'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,###.0,##,0##").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(1000.123456).should(eq("1,000.1,23,456"))
    formatter.format(-1000.123456).should(eq("-1,000.1,23,456"))

    formatter.format(1000.129).should(eq("1,000.129"))
    formatter.format(-1000.129).should(eq("-1,000.129"))
  end

  it "Can format pattern: '#,###.0,00,000'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,###.0,00,000").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(100000.123456).should(eq("100,000.1,23,456"))
    formatter.format(-100000.123456).should(eq("-100,000.1,23,456"))
  end

  it "Can format pattern: 'I am a prefix #'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("I am a prefix #").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format(123).should(eq("I am a prefix 123"))
    formatter.format(-123).should(eq("-I am a prefix 123"))
  end

  it "Can format pattern: '0,000' (leading zeros)", tags: "current" do
    rules, metadata = CLDR::Numbers::PatternParser.new("0,000").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format("000000000").should(eq("000,000,000"))
    formatter.format("000000000").should(eq("000,000,000"))
  end

  it "Can format pattern: '##0,000' (leading zeros)", tags: "current" do
    rules, metadata = CLDR::Numbers::PatternParser.new("##0,000").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format("000000000").should(eq("0,000,000"))
    formatter.format("000000000").should(eq("0,000,000"))
  end

  it "Can format pattern: '#,##0.##' (given as string)" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    formatter.format("1000.129").should(eq("1,000.13"))
    formatter.format("-1000.129").should(eq("-1,000.13"))
    formatter.format("1000.1").should(eq("1,000.1"))
    formatter.format("-1000.1").should(eq("-1,000.1"))
    formatter.format("100000.1859").should(eq("100,000.19"))
    formatter.format("-100000.1859").should(eq("-100,000.19"))
  end

  it "Handle invalid numbers given as strings" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse
    formatter = CLDR::Numbers::PatternFormatter(CLDR::Languages::EN).new(rules, metadata)

    {"10fw00.129", "-1v000.129", "---1000.1", "1000...1", "wasd", "12345     678 hi"}.each do |n|
      expect_raises(ArgumentError | LensExceptions::ParseError) do
        formatter.format(n)
      end
    end
  end
end
