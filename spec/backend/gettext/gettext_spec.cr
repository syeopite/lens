require "digest"
require "../../../src/backend/gettext"

describe Gettext do
  it "Able to load locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
  end

  it "Able to tokenize locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    Digest::SHA256.hexdigest(new_backend_instance.scan["example.po"].to_s).should eq("5db58843791927dc46ed39427879a33ea659a566394aaf50c7692144e386125c")
  end

  it "Able to parse locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    c = new_backend_instance.parse(new_backend_instance.scan)
  end
end
