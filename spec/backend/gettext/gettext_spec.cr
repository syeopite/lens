describe Gettext do
  po_backend = Gettext::POBackend.new("spec/backend/gettext/locales")
  mo_backend = Gettext::MOBackend.new("spec/backend/gettext/locales")

  describe Gettext::POBackend do
    describe "#parse" do
      it "#parse" do
        # The order at which indivusuial files are opened can be different
        hashed_results = Set(String).new(2)

        # In order to make results consistent across different OSs for testing, we'll go ahead and sort
        # the translations by lexicographical order. However, in order to do that we'll need to convert the
        # catalogue contents into an array first.
        po_backend.parse.values.each do |catalogues|
          catalogue_contents_as_array = [] of Tuple(String, Hash(Int8, String))

          catalogues.contents.each { |k, v| catalogue_contents_as_array << {k, v} }
          catalogue_contents_as_array.sort! { |a, b| a[0] <=> b[0] }

          sorted_catalogue = {} of String => Hash(Int8, String)

          # Before we can revert back to an Hash, the translation hashes also needs to be sorted.
          # The code for that is much like our sorting code above.
          catalogue_contents_as_array.each do |translation_block|
            translation_hashes_as_array = [] of Tuple(Int8, String)
            sorted_translation_hash = {} of Int8 => String

            translation_block[1].each { |k, v| translation_hashes_as_array << {k, v} }
            translation_hashes_as_array.sort! { |a, b| a[0] <=> b[0] }
            translation_hashes_as_array.each do |plural, string|
              sorted_translation_hash[plural] = string
            end

            sorted_catalogue[translation_block[0]] = sorted_translation_hash
          end

          hashed_results << Digest::SHA256.hexdigest(sorted_catalogue.to_s)
        end

        hashed_results.should eq Set{
          "08d2a781e9fd6599e25807a5b0b501ffced1a780f27211024d3c9d2b9f488d94",
          "d9374ebfa251b29be3e26555b04ffd928ca41e7e838889955523dad6e40e03d8",
        }
      end
    end
  end

  describe Gettext::MOBackend do
    describe "#parse" do
      it "#parse" do
        hashed_results = Set(String).new(2)

        # Refer to the corresponding #parse spec in the `Gettext::POBackend` above for more information.
        mo_backend.parse.values.each do |catalogues|
          catalogue_contents_as_array = [] of Tuple(String, Hash(Int8, String))

          catalogues.contents.each { |k, v| catalogue_contents_as_array << {k, v} }
          catalogue_contents_as_array.sort! { |a, b| a[0] <=> b[0] }

          sorted_catalogue = {} of String => Hash(Int8, String)

          catalogue_contents_as_array.each do |translation_block|
            translation_hashes_as_array = [] of Tuple(Int8, String)
            sorted_translation_hash = {} of Int8 => String

            translation_block[1].each { |k, v| translation_hashes_as_array << {k, v} }
            translation_hashes_as_array.sort! { |a, b| a[0] <=> b[0] }
            translation_hashes_as_array.each do |plural, string|
              sorted_translation_hash[plural] = string
            end

            sorted_catalogue[translation_block[0]] = sorted_translation_hash
          end

          hashed_results << Digest::SHA256.hexdigest(sorted_catalogue.to_s)
        end

        # MO files ignores translation with empty msgstrs. As such, the translation for arabic on our
        # example specs has a different hash than the PO variant.
        hashed_results.should eq Set{
          "fa315f56a0d2a6105f345c76f470374d50f790ea864472a28da8d96587bd6b60",
          "d9374ebfa251b29be3e26555b04ffd928ca41e7e838889955523dad6e40e03d8",
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
