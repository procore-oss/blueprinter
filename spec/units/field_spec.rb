# frozen_string_literal: true

describe '::Field' do
  let(:name) { :some_field_name }
  let(:method) { :some_method }

  let(:extractor) { double }
  let(:blueprint) { double }
  let(:options) { {} }

  subject(:field) { Blueprinter::Field.new(method, name, extractor, blueprint, options) }

  describe '#skip' do
    let(:field_name) { :runtime_field_name }
    let(:local_options) { {} }

    let(:if_allowed) { {if: ->(fn, obj, opts) { obj.allowed }} }
    let(:unless_prevented) { {unless: ->(fn, obj, opts) { obj.prevented }} }

    context 'with neither unless nor if' do
      let(:object) { double }

      it { is_expected.not_to be_skip(field_name, object, local_options) }

      context "with another condition" do
        let(:extra_condition) do
          extra = extra_state
          ->(_fn, _obj, _opts) { extra }
        end

        before do
          field.add_if(extra_condition)
        end

        context "when it is true" do
          let(:extra_state) { true }

          it { is_expected.not_to be_skip(field_name, object, local_options) }
        end

        context "when it is false" do
          let(:extra_state) { false }

          it { is_expected.to be_skip(field_name, object, local_options) }
        end
      end
    end

    context 'with unless only' do
      let(:object) { double(prevented: prevented) }
      let(:options) { unless_prevented }

      context "when prevented" do
        let(:prevented) { true }

        it { is_expected.to be_skip(field_name, object, local_options) }
      end

      context "when not prevented" do
        let(:prevented) { false }

        it { is_expected.not_to be_skip(field_name, object, local_options) }
      end

    end

    context 'with if only' do
      let(:object) { double(allowed: allowed) }
      let(:options) { if_allowed }

      context "when allowed" do
        let(:allowed) { true }

        it { is_expected.not_to be_skip(field_name, object, local_options) }
      end

      context "when not allowed" do
        let(:allowed) { false }

        it { is_expected.to be_skip(field_name, object, local_options) }
      end

      context "with another condition" do
        let(:extra_condition) do
          extra = extra_state
          ->(_fn, _obj, _opts) { extra }
        end

        before do
          field.add_if(extra_condition)
        end

        context "when it is true, and allowed is true" do
          let(:extra_state) { true }
          let(:allowed) { true }

          it { is_expected.not_to be_skip(field_name, object, local_options) }
        end

        context "when it is true, and allowed is false" do
          let(:extra_state) { true }
          let(:allowed) { false }

          it { is_expected.to be_skip(field_name, object, local_options) }
        end

        context "when it is false" do
          let(:extra_state) { false }
          let(:allowed) { :irrelevant }

          it { is_expected.to be_skip(field_name, object, local_options) }
        end
      end
    end

    context 'with unless and if' do
      let(:object) { double(prevented: prevented, allowed: allowed) }
      let(:options) { if_allowed.merge(unless_prevented) }

      context "when allowed, and not prevented" do
        let(:allowed) { true }
        let(:prevented) { false }

        it { is_expected.not_to be_skip(field_name, object, local_options) }
      end

      context "when allowed, and prevented" do
        let(:allowed) { true }
        let(:prevented) { true }

        it { is_expected.to be_skip(field_name, object, local_options) }
      end

      context "when not allowed, and prevented" do
        let(:allowed) { false }
        let(:prevented) { true }

        it { is_expected.to be_skip(field_name, object, local_options) }
      end

      context "when not allowed, and not prevented" do
        let(:allowed) { false }
        let(:prevented) { true }

        it { is_expected.to be_skip(field_name, object, local_options) }
      end
    end
  end
end
