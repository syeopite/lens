require "../../../src/backend/ruby-i18n-yaml"

describe "ruby-i18n-yaml" do
  it "able to parse locale files" do
    i18n_instance = RubyI18n::Yaml.new("spec/backend/ruby-i18n-yaml/locales")
  end

  # We can reuse a instance for the rest of the specs
  i18n_instance = RubyI18n::Yaml.new("spec/backend/ruby-i18n-yaml/locales")

  describe "simple usage" do
    it "fetches nested messages" do
      i18n_instance.translate("en", "nested_key.forth.forth-third.forth-third-fifth.4344").should eq("4344-message-in-nest")
    end

    it "handles plurals" do
      i18n_instance.translate("en", "possessions.fruits.apples", 5).should eq("I have 5 apples")
      i18n_instance.translate("en", "possessions.fruits.apples", 0).should eq("I have 0 apples")
      i18n_instance.translate("en", "possessions.fruits.apples", 1).should eq("I have 1 apple")
    end

    it "handles interpolation" do
      i18n_instance.translate("en", "possessions.fruits.unknown", 5, fruit: "pear").should eq("I have 5 pears")
      i18n_instance.translate("en", "possessions.fruits.unknown", 0, fruit: "pear").should eq("I have 0 pears")
      i18n_instance.translate("en", "possessions.fruits.unknown", 1, fruit: "pear").should eq("I have 1 pear")
    end
  end

  describe "complex usage" do
    # Credit https://github.com/TechMagister/i18n.cr/blob/master/spec/locales/ru.yml
    it "handles language with 'complex' plurals" do
      i18n_instance.translate("ru", "new_message", 0).should eq("у вас 0 сообщений")
      i18n_instance.translate("ru", "new_message", count: 1).should eq("у вас 1 сообщение")
      i18n_instance.translate("ru", "new_message", count: 2).should eq("у вас 2 сообщения")
      i18n_instance.translate("ru", "new_message", count: 11).should eq("у вас 11 сообщений")
    end

    it "handles subfolders" do
      i18n_instance.translate("en", "first-subfolder").should eq("first-subfolder-message")
      i18n_instance.translate("en", "second-subfolder").should eq("second-subfolder-message")

      i18n_instance.translate("en", "within-dir-with-yml-suffix").should eq("dir-with-yml-suffix-message")
    end

    it "overwritten plurals" do
      # Default
      i18n_instance.translate("en", "possessions.fruits.unknown", 0, fruit: "pear").should eq("I have 0 pears")
      i18n_instance.translate("en", "possessions.fruits.unknown", 1, fruit: "pear").should eq("I have 1 pear")

      # Swap plurals
      i18n_instance.define_rule("en", ->(n : Int32 | Int64 | Float64) { n == 1 ? "other" : "one" })

      # Altered plural rule
      i18n_instance.translate("en", "possessions.fruits.unknown", 0, fruit: "pear").should eq("I have 0 pear")
      i18n_instance.translate("en", "possessions.fruits.unknown", 1, fruit: "pear").should eq("I have 1 pears")

      # Restore and test
      i18n_instance.define_rule("en", ->(n : Int32 | Int64 | Float64) { n == 1 ? "one" : "other" })
      i18n_instance.translate("en", "possessions.fruits.unknown", 0, fruit: "pear").should eq("I have 0 pears")
      i18n_instance.translate("en", "possessions.fruits.unknown", 1, fruit: "pear").should eq("I have 1 pear")
    end

    it "handles multiple interpolations" do
      i18n_instance.translate("en", "interpolation_stress_testing.message", one: 1, two: 2, three: 3, four: 4, five: 5, six: 6, seven: 7, eight: 8, nine: 9, ten: 10).should eq ("1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10")
    end

    it "able to access items stored in arrays" do
      foods = ["Cake", "Pie", "Hamburger", "French Fries"]
      foods.each_with_index do |item, index|
        i18n_instance.translate("en", "items.foods", iter: index).should eq(item)
      end
    end
  end

  describe "localization" do
    it "is able to localize time" do
      date = Time.unix(1629520612)
      i18n_instance.localize("en", date, format: "default").should eq("2021-08-21")
      i18n_instance.localize("en", date, format: "long").should eq("July 21, 2021")
      i18n_instance.localize("en", date, format: "short").should eq("Jul 21")
    end

    it "is able to localize bytes" do
      i18n_instance.localize("en", 1000, type: "humanize", format: "storage_units").should eq("1 KB")
      i18n_instance.localize("en", 1500, type: "humanize", format: "storage").should eq("1.5 KB")
      i18n_instance.localize("en", -1500, type: "humanize", format: "storage").should eq("-1.5 KB")

      i18n_instance.localize("en", 100_000, type: "humanize", format: "storage").should eq("100 KB")
      i18n_instance.localize("en", 120_000, type: "humanize", format: "storage").should eq("120 KB")
      i18n_instance.localize("en", 102_000, type: "humanize", format: "storage").should eq("102 KB")
      i18n_instance.localize("en", -102_000, type: "humanize", format: "storage").should eq("-102 KB")

      i18n_instance.localize("en", 102_500_000_00, type: "humanize", format: "storage").should eq("10.2 GB")
      i18n_instance.localize("en", 102_500_000_00, type: "humanize", format: "bytes").should eq("10.2 GB")
      i18n_instance.localize("en", 102_500_000_00, type: "humanize", format: "byte size").should eq("10.2 GB")
      i18n_instance.localize("en", -102_500_000_00, type: "humanize", format: "byte size").should eq("-10.2 GB")
    end

    it "is able to localize decimals" do
      i18n_instance.localize("en", 1000, type: "humanize", format: "decimal").should eq("1 Thousand")
      i18n_instance.localize("en", 1500, type: "humanize", format: "decimal").should eq("1.5 Thousand")
      i18n_instance.localize("en", 2000, type: "humanize", format: "decimal").should eq("2 Thousand")

      i18n_instance.localize("en", 100_000, type: "humanize", format: "decimal").should eq("100 Thousand")
      i18n_instance.localize("en", 120_000, type: "humanize", format: "decimal").should eq("120 Thousand")
      i18n_instance.localize("en", 102_000, type: "humanize", format: "decimal").should eq("102 Thousand")

      i18n_instance.localize("en", 10_250_000_000, type: "humanize", format: "decimal").should eq("10.2 Billion")
      i18n_instance.localize("en", 10_250_500_000, type: "humanize", format: "decimal").should eq("10.3 Billion")

      i18n_instance.localize("en", 10_000_500_000_000).should eq("10 Trillion")
      i18n_instance.localize("en", 10_250_500_000_000).should eq("10.3 Trillion")
      i18n_instance.localize("en", 10_200_500_000_000).should eq("10.2 Trillion")

      # Default value for humanize is decimal
      i18n_instance.localize("en", 10_000_500_000_000, type: "humanize", format: "decimal").should eq("10 Trillion")
      i18n_instance.localize("en", 10_250_500_000_000, type: "humanize").should eq("10.3 Trillion")
      i18n_instance.localize("en", 10_200_500_000_000, type: "humanize", format: "").should eq("10.2 Trillion")
    end

    it "is able to localize percentages" do
      i18n_instance.localize("en", 0.2528, type: "percentage").should eq("0.252%")
      i18n_instance.localize("en", 4.528, type: "percentage").should eq("4.53%")
      i18n_instance.localize("en", 3.528, type: "percentage").should eq("3.53%")

      i18n_instance.localize("en", 1, type: "percentage").should eq("1%")
      i18n_instance.localize("en", 1.2434, type: "percentage").should eq("1.24%")

      i18n_instance.localize("en", 100, type: "percentage").should eq("100%")
      i18n_instance.localize("en", 120, type: "percentage").should eq("120%")
      i18n_instance.localize("en", 102, type: "percentage", format: "blahblahblah").should eq("102%")

      i18n_instance.localize("en", 102.528, type: "percentage").should eq("102.53%")
    end

    it "is able to localize currency" do
      i18n_instance.localize("en", -0.2528, type: "currency").should eq("-$0.252")
      i18n_instance.localize("en", 0.2528, type: "currency").should eq("$0.252")
      i18n_instance.localize("en", 4.528, type: "currency").should eq("$4.528")
      i18n_instance.localize("en", 3.528, type: "currency").should eq("$3.528")

      i18n_instance.localize("en", 1, type: "currency").should eq("$1")
      i18n_instance.localize("en", 1.2434, type: "money").should eq("$1.243")

      i18n_instance.localize("en", 100, type: "money").should eq("$100")
      i18n_instance.localize("en", 120, type: "currency").should eq("$120")
      i18n_instance.localize("en", 102, type: "currency", format: "blahblahblah").should eq("$102")

      i18n_instance.localize("en", 102.528, type: "currency").should eq("$102.528")
    end
  end

  describe "monolingual usage" do
    it "handles switching languages" do
      i18n_instance = RubyI18n::Yaml.new("spec/backend/ruby-i18n-yaml/locales")
      i18n_instance.translate("new_messages", 0).should eq("you have 0 messages")
      i18n_instance.translate("new_messages", 1).should eq("you have 1 message")

      i18n_instance.select("ru")

      i18n_instance.translate("new_message", 0).should eq("у вас 0 сообщений")
      i18n_instance.translate("new_message", count: 1).should eq("у вас 1 сообщение")

      i18n_instance.select("en")

      i18n_instance.translate("new_messages", 0).should eq("you have 0 messages")
      i18n_instance.translate("new_messages", 1).should eq("you have 1 message")
    end
  end
end
