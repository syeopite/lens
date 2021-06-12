require "digest"
require "../../../src/backend/gettext"

describe Gettext do
  it "Able to load locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
  end

  it "Able to tokenlize locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
    Digest::SHA256.hexdigest(new_backend_instance.scan["example.po"].to_s).should eq("dc8c3e87611a63f9eedc7acc12650793834230ddf42a4a2066134aa616fed473")
  end
end
