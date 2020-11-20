describe 'Blueprinter::Deprecation' do
  describe '#report' do
    TEST_MESSAGE = "Test Message"

    after { reset_blueprinter_config! }

    describe "when deprecation behavior is `:stderror`" do
      before do
        Blueprinter.configure { |config| config.deprecations = :stderror }
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      it('writes deprecation warning message to $stderr') do
        Blueprinter::Deprecation.report(TEST_MESSAGE)
        $stderr.rewind
        stderr_output = $stderr.string.chomp
        expect(stderr_output).to eql("[DEPRECATION::WARNING] Blueprinter: #{TEST_MESSAGE}")
      end

      after do
        $stderr = @orig_stderr
      end
    end

    describe "when deprecation behavior is `:silence`" do
      before do
        Blueprinter.configure { |config| config.deprecations = :silence }
        @orig_stderr = $stderr
        $stderr = StringIO.new
      end

      it('does not warn or raise deprecation message') do
        expect {Blueprinter::Deprecation.report(TEST_MESSAGE)}.not_to raise_error
        $stderr.rewind
        stderr_output = $stderr.string.chomp
        expect(stderr_output).not_to include("[DEPRECATION::WARNING] Blueprinter: #{TEST_MESSAGE}")
      end

      after do
        $stderr = @orig_stderr
      end
    end

    describe "when deprecation behavior is `:raise`" do
      before do
        Blueprinter.configure { |config| config.deprecations = :raise }
      end

      it('raises BlueprinterDeprecationError with deprecation message') do
        expect {Blueprinter::Deprecation.report(TEST_MESSAGE)}.
          to raise_error(Blueprinter::BlueprinterError, "[DEPRECATION::WARNING] Blueprinter: #{TEST_MESSAGE}")
      end
    end
  end
end
