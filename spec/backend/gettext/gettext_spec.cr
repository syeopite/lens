require "digest"
require "../../../src/backend/gettext"

describe Gettext do
  describe "po" do
    it "Able to tokenize po files" do
      new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
      Digest::SHA256.hexdigest(new_backend_instance.scan["example.po"].to_s).should eq("5db58843791927dc46ed39427879a33ea659a566394aaf50c7692144e386125c")
    end

    it "Able to parse and use po files" do
      new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
      c = new_backend_instance.parse(new_backend_instance.scan)["ar_SA"]

      c.gettext("%i line of file “%s” was not loaded correctly.").should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 0).should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 40).should eq("%i سطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 100).should eq("%i آسطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.pgettext("column/row header", "Needs Work").should eq("تحتاج عملًا")

      c.headers["Plural-Forms"].should eq("nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 && n%100<=99 ? 4 : 5);")
    end

    describe "nest" do
      new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
      tokens = new_backend_instance.scan

      it "Able to tokenize nested po files correctly" do
        Digest::SHA256.hexdigest(tokens["en.po"].to_s).should eq("826e1bc3bbc911681889585d6f8c8a5f7ddc8e919a026ba611e9a3a9a9224a69")
        Digest::SHA256.hexdigest(tokens["en.po2"].to_s).should eq("c18638ea2c5b989b8b576f92300b98aa19114058dfa9a93d819dfc29d247e13a")
        Digest::SHA256.hexdigest(tokens["en.po3"].to_s).should eq("01c162ca40618e69a967e60d0a712b94affdb432b1c96e7f8a99e49f64a54c01")
      end

      it "Able to parse and use nested po files" do
        c = new_backend_instance.parse(tokens)["en_US"]

        c.gettext("first").should eq("translated first")
        c.gettext("second").should eq("translated second")
        c.gettext("compound-message").should eq("12345")

        # Did duplicate files get merged?
        c.gettext("first-subfolder").should eq("first-subfolder-message")
        c.gettext("second-subfolder").should eq("second-subfolder-message")

        # Plurals
        c.ngettext("I have %{count} apple", "I have %{count} apples", 0).should eq("Translated: I have %{count} apples")
        c.ngettext("I have %{count} apple", "I have %{count} apples", 1).should eq("Translated: I have %{count} apple")
      end
    end
  end

  describe "mo" do
    it "able to parse and use mo files" do
      new_backend_instance = Gettext::MOBackend.new("spec/backend/gettext/locales")
      c = new_backend_instance.parse["ar_SA"]

      c.gettext("%i line of file “%s” was not loaded correctly.").should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 0).should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 40).should eq("%i سطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 100).should eq("%i آسطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.pgettext("column/row header", "Needs Work").should eq("تحتاج عملًا")

      c.headers["Plural-Forms"].should eq("nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 && n%100<=99 ? 4 : 5);")
    end

    describe "nest" do
      it "able to parse and use nested mo files" do
        new_backend_instance = Gettext::MOBackend.new("spec/backend/gettext/locales")
        c = new_backend_instance.parse["en_US"]

        c.gettext("first").should eq("translated first")
        c.gettext("second").should eq("translated second")
        c.gettext("compound-message").should eq("12345")

        # Did duplicate files get merged?
        c.gettext("first-subfolder").should eq("first-subfolder-message")
        c.gettext("second-subfolder").should eq("second-subfolder-message")

        # Plurals
        c.ngettext("I have %{count} apple", "I have %{count} apples", 0).should eq("Translated: I have %{count} apples")
        c.ngettext("I have %{count} apple", "I have %{count} apples", 1).should eq("Translated: I have %{count} apple")
      end
    end
  end
end
