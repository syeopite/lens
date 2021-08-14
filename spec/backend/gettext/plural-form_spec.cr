require "digest"
require "../../../src/backend/gettext/plural-forms/*"

describe Gettext::PluralForm do
  describe Gettext::PluralForm::Scanner do
    it "is able to tokenize a simple plural form expression" do
      plural_form_scanner = Gettext::PluralForm::Scanner(Gettext::PluralForm::Token).new("nplurals=2; plural=(n > 1);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "bdf1aa90c05da1887d5eb4d43083abfc4107f623e4a05fdbbf8ea804c12c026e"
    end

    it "is able to tokenize a complex plural form expressions" do
      plural_form_scanner = Gettext::PluralForm::Scanner(Gettext::PluralForm::Token).new("nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);")
      Digest::SHA256.hexdigest(plural_form_scanner.scan.to_s).should eq "286a6c1a2856720d784d4630696fe8aadbfbdc5c1d29ec84a7738d00a69dd85b"
    end
  end

  describe Gettext::PluralForm::Parser do
    it "is able to parse a simple plural form expression" do
      expressions = Gettext::PluralForm::Parser.new("nplurals=2; plural=(n > 1);").parse
    end

    it "is able to parse a complex plural form expression" do
      expressions = Gettext::PluralForm::Parser.new("nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);").parse
    end
  end

  describe Gettext::PluralForm::Interpreter do
    it "is able to interpret a simple plural form expression" do
      expressions = Gettext::PluralForm::Parser.new("nplurals=2; plural=(n > 1);").parse
      interpreter = Gettext::PluralForm::Interpreter.new(expressions)

      [0, 1, -3288923893892389238].each { |i| interpreter.interpret(i).should eq 0 }
      [0.0, 0.3, 0.5, 0.25, -3288923893892389238].each { |i| interpreter.interpret(i).should eq 0 }

      [2, 3, 4, 100, 30, 50, 3239, 323, 3288923893892389238].each { |i| interpreter.interpret(i).should eq 1 }
      [2.0, 3.5, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0, 3288923893892389238.0].each { |i| interpreter.interpret(i).should eq 1 }
    end

    it "is able to interpret a complex plural form expression" do
      expressions = Gettext::PluralForm::Parser.new("nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2);").parse
      interpreter = Gettext::PluralForm::Interpreter.new(expressions)

      # https://unicode-org.github.io/cldr-staging/charts/37/supplemental/language_plural_rules.html
      [1, 21, 31, 41, 51, 61, 71, 81, 101, 1001].each { |i| interpreter.interpret(i).should eq 0 }
      [1.0, 21.0, 31.0, 41.0, 51.0, 61.0, 71.0, 81.0, 101.0, 1001.0].each { |i| interpreter.interpret(i).should eq 0 }

      [2, 3, 4, 22, 23, 24, 32, 33, 34, 42, 43, 44, 52, 53, 54, 62, 102, 1002].each { |i| interpreter.interpret(i).should eq 1 }
      [2.0, 3.0, 4.0, 22.0, 23.0, 24.0, 32.0, 33.0, 102.0, 1002.0].each { |i| interpreter.interpret(i).should eq 1 }

      [0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 100, 1000, 10000, 100000, 1000000].each { |i| interpreter.interpret(i).should eq 2 }
      [0.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0].each { |i| interpreter.interpret(i).should eq 2 }
    end
  end
end
