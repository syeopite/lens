require "../../../src/cldr/logic/number_properties.cr"

describe CLDR::Plurals do
  string_test_case = {
    {"1", 1, 1, 0, 0, 0, 0},
    {"1.0", 1, 1, 1, 0, 0, 0},
    {"1.00", 1, 1, 2, 0, 0, 0},
    {"1.3", 1.3, 1, 1, 1, 3, 3},
    {"1.30", 1.3, 1, 2, 1, 30, 3},
    {"1.03", 1.03, 1, 2, 2, 3, 3},
    {"1.230", 1.23, 1, 3, 2, 230, 23},
    {"1200000", 1200000, 1200000, 0, 0, 0, 0},
    {"1200.50", 1200.5, 1200, 2, 1, 50, 5},
  }

  int_test_case = {
    {1, 1, 1, 0, 0, 0, 0},
    {1.0, 1, 1, 1, 0, 0, 0},
    {1.00, 1, 1, 1, 0, 0, 0},
    {1.3, 1.3, 1, 1, 1, 3, 3},
    {1.30, 1.3, 1, 1, 1, 3, 3},
    {1.03, 1.03, 1, 2, 2, 3, 3},
    {1.230, 1.23, 1, 2, 2, 23, 23},
    {1200000, 1200000, 1200000, 0, 0, 0, 0},
    {1200.50, 1200.5, 1200, 1, 1, 5, 5},
  }

  it "#get_n" do
    string_test_case.each do |source, string_n_spec|
      CLDR::Plurals.get_n(source).should(eq(string_n_spec))
    end

    int_test_case.each do |source, num_n_spec|
      CLDR::Plurals.get_n(source).should(eq(num_n_spec))
    end
  end

  it "#get_i" do
    string_test_case.each do |source, _, string_i_spec|
      CLDR::Plurals.get_i(source).should(eq(string_i_spec))
    end

    int_test_case.each do |source, _, num_i_spec|
      CLDR::Plurals.get_i(source).should(eq(num_i_spec))
    end
  end

  it "#get_v" do
    string_test_case.each do |source, _, _, string_v_spec|
      CLDR::Plurals.get_v(source).should(eq(string_v_spec))
    end

    int_test_case.each do |source, _, _, num_v_spec|
      CLDR::Plurals.get_v(source).should(eq(num_v_spec))
    end
  end

  it "#get_w" do
    string_test_case.each do |source, _, _, _, string_w_spec|
      CLDR::Plurals.get_w(source).should(eq(string_w_spec))
    end

    int_test_case.each do |source, _, _, _, num_w_spec|
      CLDR::Plurals.get_w(source).should(eq(num_w_spec))
    end
  end

  it "#get_f" do
    string_test_case.each do |source, _, _, _, _, string_f_spec|
      CLDR::Plurals.get_f(source).should(eq(string_f_spec))
    end

    int_test_case.each do |source, _, _, _, _, num_f_spec|
      CLDR::Plurals.get_f(source).should(eq(num_f_spec))
    end
  end

  it "#get_t" do
    string_test_case.each do |source, _, _, _, _, _, string_t_spec|
      CLDR::Plurals.get_t(source).should(eq(string_t_spec))
    end

    int_test_case.each do |source, _, _, _, _, _, num_t_spec|
      CLDR::Plurals.get_t(source).should(eq(num_t_spec))
    end
  end
end
