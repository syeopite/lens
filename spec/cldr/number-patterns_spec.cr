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
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.##").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("b7eb419d7f755e8258d1de10b73fbb9dcf45e9532a3d8336d46c905c0991b2c9"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("3e4bb9056cad89d7814db01ec8c9aeb79782de80dfa9cad2c1aff5a3dfd9b14c"))
  end

  # TODO
  # it "Can parse pattern: '0.00+;0.00-'" do
  #   rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("0.00+;0.00-").parse
  # end

  it "Can parse pattern '###0.0000#'" do
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("###0.0000#").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(nil))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("56b858c3e4157c6fce3a6941f35eb4758892e9fc0698424a3b0506732660454d"))
  end

  it "Can parse pattern '00000.0000'" do
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("00000.0000").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(nil))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("a6cc89f0edb84aeea108beacb2d843b69b0b571093c05a7e3ea9c0dca7f2529c"))
  end

  it "Can parse pattern '#,##0.00 ¤'" do
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("#,##0.00 ¤").parse

    metadata.secondary_grouping.should(eq(nil))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(false))
    metadata.padding_character.should(eq(nil))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("d5e330e30ef614845533058658802ee95fe8197461b7f1441b00f16318f5e9c8"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("5cdfd9594341dc8a00de80afd39a31a73f85a24469fed17e112cf0bb950958b6"))
  end

  it "Can parse pattern '*x #,##,##0.###'" do
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("*x #,##,##0.###").parse

    metadata.secondary_grouping.should(eq(2))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(true))
    metadata.padding_character.should(eq("x"))
    metadata.maximum_significant_figures.should(eq(nil))
    metadata.minimum_significant_figures.should(eq(nil))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("0a8333eb12ab400404d2ebc60f6a07b3fbb0aa18d745f303c7676d707e7bd892"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("9366e1ee0e2281a95b4acf90472f2c9c619a49310c6974adaf62f989d5172bd9"))
  end

  it "Can parse pattern '*x #,##,@@@##0.###'" do
    rules, fractional_rules, metadata = CLDR::Numbers::PatternParser.new("*x #,##,@@@##0.###").parse

    metadata.secondary_grouping.should(eq(2))
    metadata.primary_grouping.should(eq(3))
    metadata.use_padding.should(eq(true))
    metadata.padding_character.should(eq("x"))
    metadata.maximum_significant_figures.should(eq(6))
    metadata.minimum_significant_figures.should(eq(3))

    Digest::SHA256.hexdigest(rules.to_s).should(eq("0a8333eb12ab400404d2ebc60f6a07b3fbb0aa18d745f303c7676d707e7bd892"))
    Digest::SHA256.hexdigest(fractional_rules.to_s).should(eq("9366e1ee0e2281a95b4acf90472f2c9c619a49310c6974adaf62f989d5172bd9"))
  end
end
