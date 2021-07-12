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
  end

  describe "mo" do
    it "Able to parse and use mo files" do
      new_backend_instance = Gettext::MOBackend.new("spec/backend/gettext/locales")
      c = new_backend_instance.parse["ar_SA"]

      c.gettext("%i line of file “%s” was not loaded correctly.").should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 0).should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 40).should eq("%i سطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 100).should eq("%i آسطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
      c.pgettext("column/row header", "Needs Work").should eq("تحتاج عملًا")

      c.headers["Plural-Forms"].should eq("nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 && n%100<=99 ? 4 : 5);")
    end
  end
end
