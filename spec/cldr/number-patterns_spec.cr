require "digest"
require "../../src/cldr/logic/numbers/lexer"
require "../../src/cldr/logic/numbers/parser"

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

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("7f477a11929fc9493bda3b7fb308fe6b5380c97fb2d1e52d7765f0343b28b60e"))
  end

  # TODO
  # it "Can parse pattern: '0.00+;0.00-'" do
  #   rules, metadata = CLDR::Numbers::PatternParser.new("0.00+;0.00-").parse
  # end

  it "Can parse pattern '###0.0000#'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("###0.0000#").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(nil))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("56b858c3e4157c6fce3a6941f35eb4758892e9fc0698424a3b0506732660454d"))
  end

  it "Can parse pattern '00000.0000'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("00000.0000").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(nil))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("ca9d0899f300a54b7f8c82a7353dc4c02328feea6304bf12958cf6337d9787cb"))
  end

  it "Can parse pattern '#,##0.00 ¤'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.00 ¤").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("f766b8013b2eea254365f49d3900c99aec84986d01f891928ff96d5f3bb37cb7"))
  end

  it "Can parse pattern '*x #,##,##0.###'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("*x #,##,##0.###").parse

    metadata.secondary_grouping.should(eq(2))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(true))
    metadata.padding_character.should(eq("x"))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("93d6089eb1b1aa1c4c236005fe92baa4e0b44fb662ae7ebad3f55ece79f07090"))
  end

  it "Can parse pattern '*x #,##,@@@##0.###'" do
    rules, metadata = CLDR::Numbers::PatternParser.new("*x #,##,@@@##0.###").parse

    metadata.secondary_grouping.should(eq(2))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(true))
    metadata.padding_character.should(eq("x"))
    metadata.maximum_significant_figures.should(eq(6))
    metadata.minimum_significant_figures.should(eq(3))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("93d6089eb1b1aa1c4c236005fe92baa4e0b44fb662ae7ebad3f55ece79f07090"))
  end
end
