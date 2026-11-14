# frozen_string_literal: true

describe Blueprinter::V2::Compiler::Source do
  let(:code) { described_class.new }

  it 'emits statements in order' do
    code.line 'foo'
    code.assign 'bar', '42'

    expect(code.to_s).to eq "foo\nbar = 42\n"
  end

  it 'indents a block and closes it' do
    code.open 'if foo' do
      code.line 'bar'
      code.open 'if baz' do
        code.line 'qux'
      end
    end

    expect(code.to_s).to eq <<~RUBY
      if foo
        bar
        if baz
          qux
        end
      end
    RUBY
  end

  it 'emits the body with no wrapper when a condition is nil' do
    code.if_(nil) { code.line 'foo' }
    code.unless_(nil) { code.line 'bar' }

    expect(code.to_s).to eq "foo\nbar\n"
  end

  it 'wraps the body when a condition is given' do
    code.if_('a') { code.line 'foo' }
    code.unless_('b') { code.line 'bar' }

    expect(code.to_s).to eq "if a\n  foo\nend\nunless b\n  bar\nend\n"
  end

  it 'produces parseable Ruby' do
    code.open 'def thing(x)' do
      code.assign 'y', 'x + 1'
      code.if_('y > 2') { code.line 'y' }
    end

    expect { RubyVM::InstructionSequence.compile(code.to_s) }.to_not raise_error
  end
end
