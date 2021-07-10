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
    Digest::SHA256.hexdigest(new_backend_instance.scan["example.po"].to_s).should eq("cdae62bade2a9e21aaff07bd43d2714e4032c3d2ead71ee0f6b7e47a9f27a610")
  end

  it "Able to parse locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    new_backend_instance.parse(new_backend_instance.scan)
  end
end
