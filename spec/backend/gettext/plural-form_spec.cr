require "../../../src/backend/gettext/plural-forms/*"

describe PluralForm do
  describe "Scanner" do
    it "is able to tokenize a simple plural form expression" do
      plural_form_scanner = PluralForm::Scanner.new("nplurals=2; plural=(n > 1);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "576fccccc5bd649076cb7209a91db5192e26937b18bfd293cc9e3d01b8ea0cef"
    end

    it "is able to tokenize a complex plural form expressions" do
      plural_form_scanner = PluralForm::Scanner.new("nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "fe58796b4c706c1476ee8daee0b8a1f57514811cdbb0e8a8db152b686a0751cf"
    end
  end
end
