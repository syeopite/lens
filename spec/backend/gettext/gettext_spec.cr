require "digest"
require "../../../src/backend/gettext"
require "benchmark"

describe Gettext do
  it "Able to load locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
  end

  it "Able to tokenize locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    Digest::SHA256.hexdigest(new_backend_instance.scan["example.po"].to_s).should eq("6b99ee1bf61ea926df4d07fafb4e30631946ad4014f1ff7c01521bbf8d722355")
  end

  it "Able to parse locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    new_backend_instance.parse(new_backend_instance.scan)
  end
end
