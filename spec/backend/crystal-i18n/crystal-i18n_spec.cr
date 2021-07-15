require "../../../src/backend/crystal-i18n"

describe "crystal-i18n" do
  it "able to parse locale files" do
    i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")
  end

  describe "simple usage" do
    i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")

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
    i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")

    # Credit https://github.com/TechMagister/i18n.cr/blob/master/spec/locales/ru.yml
    it "handles language with 'complex' plurals" do
      i18n_instance.translate("ru", "new_message", 0).should eq("у вас 0 сообщений")
      i18n_instance.translate("ru", "new_message", count: 1).should eq("у вас 1 сообщение")
      i18n_instance.translate("ru", "new_message", count: 2).should eq("у вас 2 сообщения")
      i18n_instance.translate("ru", "new_message", count: 11).should eq("у вас 11 сообщений")
    end

    it "handles subfolders" do
      i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")
      i18n_instance.translate("en", "first-subfolder").should eq("first-subfolder-message")
      i18n_instance.translate("en", "second-subfolder").should eq("second-subfolder-message")

      i18n_instance.translate("en", "within-dir-with-yml-suffix").should eq("dir-with-yml-suffix-message")
    end

    it "overwritten plurals" do
      i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")

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

  describe "monolingual usage" do
    it "handles switching languages" do
      i18n_instance = CrystalI18n::I18n.new("spec/backend/crystal-i18n/locales")
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