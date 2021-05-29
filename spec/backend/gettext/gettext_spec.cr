require "../../../src/backend/gettext"

describe Gettext do
  it "Able to load locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    new_backend_instance.load
  end

  it "Able to tokenlize locale files" do
    new_backend_instance = Gettext::POBackend.new("spec/backend/gettext/locales")
    timeit new_backend_instance.load
    timeit new_backend_instance.scan
  end
end
