require "digest"
require "../../src/cldr/logic/numbers/lexer"

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
