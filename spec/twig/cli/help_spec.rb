require 'spec_helper'

describe Twig::Cli::Help do
  Help = Twig::Cli::Help

  describe '.description' do
    before :each do
      @twig = Twig.new
    end

    it 'returns short text in a single line' do
      text = 'The quick brown fox.'
      result = Help.description(text, :width => 80)
      expect(result).to eq([text])
    end

    it 'returns long text in a string with line breaks' do
      text = 'The quick brown fox jumps over the lazy, lazy dog.'
      result = Help.description(text, :width => 20)
      expect(result).to eq([
        'The quick brown fox',
        'jumps over the lazy,',
        'lazy dog.'
      ])
    end

    it 'breaks a long word by max line length' do
      text = 'Thequickbrownfoxjumpsoverthelazydog.'
      result = Help.description(text, :width => 20)
      expect(result).to eq([
        'Thequickbrownfoxjump',
        'soverthelazydog.'
      ])
    end

    it 'adds a blank line' do
      text = 'The quick brown fox.'
      result = Help.description(text, :width => 80, :add_blank_line => true)
      expect(result).to eq([text, ' '])
    end
  end

  describe '.description_for_custom_property' do
    before :each do
      @twig = Twig.new
    end

    it 'returns a help string for a custom property' do
      option_parser = OptionParser.new
      expect(Help).to receive(:print_section) do |opt_parser, desc, options|
        expect(opt_parser).to eq(option_parser)
        expect(desc).to eq("      --test-option                Test option description\n")
        expect(options).to eq(:trailing => "\n")
      end

      Help.description_for_custom_property(option_parser, [
        ['--test-option', 'Test option description']
      ])
    end

    it 'supports custom trailing whitespace' do
      option_parser = OptionParser.new
      expect(Help).to receive(:print_section) do |opt_parser, desc, options|
        expect(opt_parser).to eq(option_parser)
        expect(desc).to eq("      --test-option                Test option description\n")
        expect(options).to eq(:trailing => '')
      end

      Help.description_for_custom_property(option_parser, [
        ['--test-option', 'Test option description']
      ], :trailing => '')
    end
  end

  describe '.line_for_custom_property?' do
    before :each do
      @twig = Twig.new
    end

    it 'returns true for `--except-foo`' do
      expect(Help.line_for_custom_property?('  --except-foo  ')).to eql(true)
    end

    it 'returns false for `--except-branch`' do
      expect(Help.line_for_custom_property?('  --except-branch  ')).to be_falsy
    end

    it 'returns false for `--except-property`' do
      expect(Help.line_for_custom_property?('  --except-property  ')).to be_falsy
    end

    it 'returns false for `--except-PROPERTY`' do
      expect(Help.line_for_custom_property?('  --except-PROPERTY  ')).to be_falsy
    end

    it 'returns true for `--only-foo`' do
      expect(Help.line_for_custom_property?('  --only-foo  ')).to eql(true)
    end

    it 'returns false for `--only-branch`' do
      expect(Help.line_for_custom_property?('  --only-branch  ')).to be_falsy
    end

    it 'returns false for `--only-property`' do
      expect(Help.line_for_custom_property?('  --only-property  ')).to be_falsy
    end

    it 'returns false for `--only-PROPERTY`' do
      expect(Help.line_for_custom_property?('  --only-PROPERTY  ')).to be_falsy
    end

    it 'returns true for `--foo-width`' do
      expect(Help.line_for_custom_property?('  --foo-width  ')).to eql(true)
    end

    it 'returns false for `--branch-width`' do
      expect(Help.line_for_custom_property?('  --branch-width  ')).to be_falsy
    end

    it 'returns false for `--PROPERTY-width`' do
      expect(Help.line_for_custom_property?('  --PROPERTY-width  ')).to be_falsy
    end
  end

  describe '.paragraph' do
    before :each do
      @twig = Twig.new
    end

    it 'returns long text in a paragraph with line breaks' do
      text = Array.new(5) do
        'The quick brown fox jumps over the lazy dog.'
      end.join(' ')

      result = Help.paragraph(text)

      expect(result).to eq([
        'The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the',
        'lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps',
        'over the lazy dog. The quick brown fox jumps over the lazy dog.'
      ].join("\n"))
    end
  end

  describe '.subcommand_descriptions' do
    it 'returns a word-wrapped list of subcommand descriptions' do
      output_lines = Help.subcommand_descriptions

      # Some lines are actually multi-line descriptions. Split them so we can
      # count characters per line.
      output_lines = output_lines.map { |line| line.split("\n") }.flatten

      output_line_max_width = output_lines.map { |line| line.length }.max
      expect(output_line_max_width).to be <= Help.console_width
    end
  end

  describe '.header' do
    it 'generates a header section' do
      option_parser = double
      text = 'Some header'
      expected_text = "Some header\n==========="
      expect(Help).to receive(:print_section).with(
        option_parser,
        expected_text,
        :trailing => "\n\n"
      )

      Help.header(option_parser, text)
    end
  end

  describe '.subheader' do
    it 'generates a subheader section' do
      option_parser = double
      text = 'Some subheader'
      expected_text = "Some subheader\n--------------"
      expect(Help).to receive(:print_section).with(
        option_parser,
        expected_text,
        :trailing => "\n\n"
      )

      Help.subheader(option_parser, text)
    end
  end
end
