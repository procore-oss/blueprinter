# frozen_string_literal: true

RSpec.shared_examples "generated_file" do
  it { is_expected.to have_correct_syntax }
end
