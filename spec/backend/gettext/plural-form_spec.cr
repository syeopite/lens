require "../../../src/backend/gettext/plural-forms/*"

describe PluralForm do
  describe "Scanner" do
    it "is able to tokenize a simple plural form expression" do
      plural_form_scanner = PluralForm::Scanner.new("nplurals=2; plural=(n > 1);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "35d0b0e40657d062813e8046250e9beac490db3df8171a29c4306015b35b674b"
    end

    it "is able to tokenize a complex plural form expressions" do
      plural_form_scanner = PluralForm::Scanner.new("nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "9bd2c11c01828c71757f572f1cc651fc71f4ff832f3b62562303811b965d1d19"
    end
  end
end
