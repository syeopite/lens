describe Gettext do
  po_backend = Gettext::POBackend.new("spec/backend/gettext/locales")
  mo_backend = Gettext::MOBackend.new("spec/backend/gettext/locales")

  describe Gettext::POBackend do
    describe "#parse" do
      it "#parse" do
        hashed_results = Set(String).new(2)
        po_backend.parse.values.each { |catalogues| hashed_results << Digest::SHA256.hexdigest(catalogues.contents.to_s) }

        hashed_results.should eq Set{
          "14a1b3c08a51ff9eaf1596d846a46412664d682f658f178cb6f13ace13b4f4cc",
          "47b914b5b0b8506ecd09ad27903e9e10eedd268743b27b5c9f22a30a7b9af938",
        }
      end
    end
  end

  describe Gettext::MOBackend do
    describe "#parse" do
      it "#parse" do
        hashed_results = Set(String).new(2)
        mo_backend.parse.values.each { |catalogues| hashed_results << Digest::SHA256.hexdigest(catalogues.contents.to_s) }

        # Order of strings is slightly different but should have no impact on the final result
        hashed_results.should eq Set{
          "07079054d4b59c25a46747925ccfe45fbccf65c01d80c86e1b5f014491b92d29",
          "5cdf81a98852f00fedb22cf2bcb507455a63466ab5db4eaaabd61a810ef7645b",
        }
      end
    end
  end

  describe "Usage" do
    mo_catalogue = Gettext::MOBackend.new("spec/backend/gettext/locales").create
    po_catalogue = Gettext::POBackend.new("spec/backend/gettext/locales").create
    test_methods = [{"Po", po_catalogue}, {"Mo", mo_catalogue}]

    describe "Simple" do
      test_methods.each do |method, catalogue|
        describe method do
          it "Can fetch message" do
            catalogue["ar_SA"].gettext("%i line of file “%s” was not loaded correctly.").should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
            catalogue["en_US"].gettext("first").should eq("translated first")
            catalogue["en_US"].gettext("second").should eq("translated second")
          end

          it "Can handle plurals" do
            catalogue["en_US"].ngettext("I have %{count} apple", "I have %{count} apples", 0).should eq("Translated: I have %{count} apples")
            catalogue["en_US"].ngettext("I have %{count} apple", "I have %{count} apples", 1).should eq("Translated: I have %{count} apple")
          end

          it "Has correct plural forms" do
            catalogue["ar_SA"].headers["Plural-Forms"].should eq("nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 && n%100<=99 ? 4 : 5);")
            catalogue["en_US"].headers["Plural-Forms"].should eq("nplurals=2; plural=n != 1;")
          end
        end
      end
    end

    describe "Advanced" do
      test_methods.each do |method, catalogue|
        describe method do
          it "Can handle complex plurals" do
            catalogue["ar_SA"].ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 0).should eq("%i سطر ملف ““%s”” لم يتم تحميله بشكل صحيح.")
            catalogue["ar_SA"].ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 40).should eq("%i سطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
            catalogue["ar_SA"].ngettext("%i line of file “%s” was not loaded correctly.", "%i lines of file “%s” were not loaded correctly.", 100).should eq("%i آسطر الملف ““%s”” لم يتم تحميله بشكل صحيح.")
          end

          it "Can handle nested structure with duplicate files" do
            catalogue["en_US"].gettext("first-subfolder").should eq("first-subfolder-message")
            catalogue["en_US"].gettext("second-subfolder").should eq("second-subfolder-message")
          end

          it "Can handle messages constrainted by context" do
            catalogue["ar_SA"].pgettext("column/row header", "Needs Work").should eq("تحتاج عملًا")
          end
        end
      end
    end
  end
end
