require 'spec_helper'

describe Twig::Display do
  before :each do
    @twig = Twig.new
  end

  describe '.unformat_string' do
    it 'unformats a plain text string' do
      string = 'foo'
      expect(Twig::Display.unformat_string(string)).to eq(string)
    end

    it 'unformats a string with color' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :color => :red)
      expect(formatted_string.size).to be > 3

      expect(Twig::Display.unformat_string(formatted_string)).to eq(string)
    end

    it 'unformats a string with weight' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :weight => :bold)
      expect(formatted_string.size).to be > 3

      expect(Twig::Display.unformat_string(formatted_string)).to eq(string)
    end

    it 'unformats a string with color and weight' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :color => :red, :weight => :bold)
      expect(formatted_string.size).to be > 3

      expect(Twig::Display.unformat_string(formatted_string)).to eq(string)
    end
  end

  describe '#column' do
    it 'returns a string with an exact fixed width' do
      expect(@twig.column('foo', :width => 8)).to eq('foo' + (' ' * 5))
    end

    it 'returns a string that fits a column exactly' do
      expect(@twig.column('asdfasdf', :width => 8)).to eq('asdfasdf')
    end

    it 'truncates a wide string with an ellipsis' do
      expect(@twig.column('asdfasdfasdf', :width => 8)).to eq('asdfa...')
    end

    it 'passes options through to `format_string`' do
      format_options = { :color => :red, :weight => :bold }
      expect(@twig).to receive(:format_string).
        with('foo' + (' ' * 5), format_options)

      @twig.column('foo', format_options)
    end
  end

  describe '#property_column_width' do
    it 'returns a default width if no property name is given' do
      expect(@twig.property_column_width).to eq(
        Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
      )
    end

    context 'with no custom column widths set' do
      before :each do
        expect(@twig.options[:property_width]).to be_nil
      end

      it 'returns a default width if a property name is given' do
        expect(@twig.property_column_width(:foo)).to eq(
          Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
        )
      end

      it 'returns a default width if :branch is given' do
        expect(@twig.property_column_width(:branch)).to eq(
          Twig::Display::DEFAULT_BRANCH_COLUMN_WIDTH
        )
      end
    end

    context 'with custom column widths set' do
      it 'returns a default width if a property name is given but it has no custom width' do
        expect(@twig.property_column_width(:baz)).to eq(
          Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
        )
      end

      it 'returns a custom width if a property name is given and it has a custom width' do
        @twig.set_option(:property_width, :foo => 20)
        expect(@twig.property_column_width(:foo)).to eq(20)
      end

      it 'returns a default width if :branch is given but it has no custom width' do
        expect(@twig.property_column_width(:branch)).to eq(
          Twig::Display::DEFAULT_BRANCH_COLUMN_WIDTH
        )
      end

      it 'returns a custom width if :branch is given but it has no custom width' do
        @twig.set_option(:property_width, :branch => 20)
        expect(@twig.property_column_width(:branch)).to eq(20)
      end
    end
  end

  describe '#branch_list_headers' do
    before :each do
      allow(Twig::Branch).to receive(:all_property_names) { %w[foo quux] }
    end

    it 'returns a string of branch properties and underlines' do
      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      column_gutter = @twig.column_gutter
      expect(result_lines[0]).to eq(
        (' ' * date_time_column_width) + column_gutter +
        'foo     ' + (' ' * extra_property_column_width) + column_gutter +
        'quux    ' + (' ' * extra_property_column_width) + column_gutter +
        '  branch'
      )
      expect(result_lines[1]).to eq(
        (' ' * date_time_column_width) + column_gutter +
        '---     ' + (' ' * extra_property_column_width) + column_gutter +
        '----    ' + (' ' * extra_property_column_width) + column_gutter +
        '  ------'
      )
    end

    it 'only includes certain property names' do
      @twig.set_option(:property_only_name, /foo/)

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      expect(result_lines[0]).to include('foo')
      expect(result_lines[0]).not_to include('quux')
      expect(result_lines[0]).to include('branch')
    end

    it 'excludes certain property names' do
      @twig.set_option(:property_except_name, /foo/)

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      expect(result_lines[0]).not_to include('foo')
      expect(result_lines[0]).to include('quux')
      expect(result_lines[0]).to include('branch')
    end

    it 'sets a header width' do
      @twig.set_option(:property_width, :foo => 4)

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      column_gutter = @twig.column_gutter
      expect(result_lines[0]).to eq(
        (' ' * date_time_column_width) + column_gutter +
        'foo '     + column_gutter +
        'quux    ' + (' ' * extra_property_column_width) + column_gutter +
        '  branch'
      )
      expect(result_lines[1]).to eq(
        (' ' * date_time_column_width) + column_gutter +
        '--- '     + column_gutter +
        '----    ' + (' ' * extra_property_column_width) + column_gutter +
        '  ------'
      )
    end

    it 'sets a header color' do
      result = @twig.branch_list_headers(:header_color => :green)
      header_line = result.split("\n").first
      color = Twig::Display::COLORS[:green]
      expect(header_line.gsub(/\s/, '')).to eq(
        "\e[#{color}mfoo\e[0m" <<
        "\e[#{color}mquux\e[0m" <<
        "\e[#{color}mbranch\e[0m"
      )
    end

    it 'sets a header weight' do
      result = @twig.branch_list_headers(:header_weight => :bold)
      header_line = result.split("\n").first
      weight = Twig::Display::WEIGHTS[:bold]
      expect(header_line.gsub(/\s/, '')).to eq(
        "\e[#{weight}mfoo\e[0m" <<
        "\e[#{weight}mquux\e[0m" <<
        "\e[#{weight}mbranch\e[0m"
      )
    end

    it 'sets a header color and weight' do
      result = @twig.branch_list_headers(:header_color => :red, :header_weight => :bold)
      header_line = result.split("\n").first
      color, weight = Twig::Display::COLORS[:red], Twig::Display::WEIGHTS[:bold]
      expect(header_line.gsub(/\s/, '')).to eq(
        "\e[#{color};#{weight}mfoo\e[0m" <<
        "\e[#{color};#{weight}mquux\e[0m" <<
        "\e[#{color};#{weight}mbranch\e[0m"
      )
    end
  end

  describe '#branch_list_line' do
    before :each do
      @current_branch = Twig::Branch.new('my-branch')
      @other_branch   = Twig::Branch.new('other-branch')
      expect(@twig).to receive(:current_branch_name).and_return(@current_branch.name)
      allow(Twig::Branch).to receive(:all_property_names) { %w[foo bar] }
      allow(@current_branch).to receive(:get_properties) do
        { 'foo' => 'foo!', 'bar' => 'bar!' }
      end
      allow(@other_branch).to receive(:get_properties) do
        { 'foo' => 'foo!', 'bar' => 'bar!' }
      end
      commit_time = Twig::CommitTime.new(Time.now)
      expect(commit_time).to receive(:to_s).and_return('2000-01-01')
      allow(@current_branch).to receive(:last_commit_time) { commit_time }
      allow(@other_branch).to receive(:last_commit_time) { commit_time }
    end

    it 'returns a line for the current branch' do
      indicator     = Twig::Display::CURRENT_BRANCH_INDICATOR
      branch        = @current_branch
      branch_regexp = /#{Regexp.escape(indicator)}#{Regexp.escape(branch.name)}/

      result = @twig.branch_list_line(branch)

      expect(result).to match(/2000-01-01\s+foo!\s+bar!\s+#{branch_regexp}/)
    end

    it 'returns a line for a branch other than the current branch' do
      branch = @other_branch
      result = @twig.branch_list_line(branch)
      expect(result).to match(/2000-01-01\s+foo!\s+bar!\s+#{Regexp.escape(branch.name)}/)
    end

    it 'returns a line containing an empty branch property' do
      expect(Twig::Branch).to receive(:all_property_names).and_return(%w[foo bar baz])
      branch = @other_branch

      result = @twig.branch_list_line(branch)

      empty_indicator = Twig::Display::EMPTY_BRANCH_PROPERTY_INDICATOR
      expect(result).to match(/2000-01-01\s+foo!\s+bar!\s+#{empty_indicator}\s+#{Regexp.escape(branch.name)}/)
    end

    it 'changes line break characters to spaces' do
      branch = @current_branch
      property_names = %w[foo bar linebreaks]
      expect(branch).to receive(:get_properties).with(property_names).and_return(
        'foo' => 'foo!',
        'bar' => 'bar!',
        'linebreaks' => "line\r\nbreaks!"
      )
      expect(Twig::Branch).to receive(:all_property_names).and_return(property_names)

      result = @twig.branch_list_line(branch)

      expect(result).to include('line breaks')
    end

    it 'only includes certain property names' do
      @twig.set_option(:property_only_name, /foo/)
      branch = @current_branch
      expect(branch).to receive(:get_properties).
        with(['foo']).
        and_return('foo' => 'foo!')

      result = @twig.branch_list_line(branch)

      expect(result).to include('foo!')
    end

    it 'excludes certain property names' do
      @twig.set_option(:property_except_name, /foo/)
      branch = @current_branch
      expect(branch).to receive(:get_properties).
        with(['bar']).
        and_return('bar' => 'bar!')

      result = @twig.branch_list_line(branch)

      expect(result).to include('bar!')
    end

    it 'returns a line with custom column widths' do
      branch = @other_branch
      @twig.set_option(:property_width, :foo => 5)

      result = @twig.branch_list_line(branch)

      column_gutter = @twig.column_gutter
      expect(result).to eq(
        '2000-01-01' + (' ' * 25) + column_gutter +
        'foo! ' + column_gutter +
        'bar!' + (' ' * 12) + column_gutter +
        '  ' + branch.name
      )
    end

    context 'with a custom width for the branch column' do
      before :each do
        @twig.set_option(:property_width, :branch => 8)
      end

      it 'returns a line for the current branch' do
        indicator = Twig::Display::CURRENT_BRANCH_INDICATOR
        branch    = @current_branch

        result = @twig.branch_list_line(branch)
        unformatted_result = Twig::Display.unformat_string(result)

        column_gutter = @twig.column_gutter
        expect(unformatted_result).to eq(
          '2000-01-01' + (' ' * 25) + column_gutter +
          'foo!' + (' ' * 12) + column_gutter +
          'bar!' + (' ' * 12) + column_gutter +
          indicator + 'my-br...'
        )
      end

      it 'returns a line for a branch other than the current branch' do
        branch = @other_branch

        result = @twig.branch_list_line(branch)

        column_gutter = @twig.column_gutter
        expect(result).to eq(
          '2000-01-01' + (' ' * 25) + column_gutter +
          'foo!' + (' ' * 12) + column_gutter +
          'bar!' + (' ' * 12) + column_gutter +
          '  ' + 'other...'
        )
      end
    end
  end

  describe '#branches_json' do
    before :each do
      @property_names = %w[foo bar]
      allow(@twig).to receive(:property_names).and_return(@property_names)
    end

    it 'returns JSON for an array of branches' do
      branches = [
        Twig::Branch.new('branch1'),
        Twig::Branch.new('branch2')
      ]
      branch_hashes = [
        { 'name' => 'branch1' },
        { 'name' => 'branch2' }
      ]
      expect(@twig).to receive(:branches).and_return(branches)
      expect(branches[0]).to receive(:to_hash).
        with(@property_names).
        and_return(branch_hashes[0])
      expect(branches[1]).to receive(:to_hash).
        with(@property_names).
        and_return(branch_hashes[1])

      result = @twig.branches_json

      expect(result).to eq({ 'branches' => branch_hashes }.to_json)
    end

    it 'returns JSON for an empty array if there are no branches' do
      expect(@twig).to receive(:branches).and_return([])
      result = @twig.branches_json
      expect(result).to eq({ 'branches' => [] }.to_json)
    end
  end

  describe '#format_strings?' do
    before :each do
      @twig = Twig.new
    end

    it 'returns false if using Windows' do
      expect(Twig::System).to receive(:windows?) { true }
      expect(@twig.format_strings?).to eql(false)
    end

    it 'returns true if expected conditions pass' do
      expect(Twig::System).to receive(:windows?) { false }
      expect(@twig.format_strings?).to eql(true)
    end
  end

  describe '#format_string' do
    it 'returns a plain string' do
      expect(@twig.format_string('foo', {})).to eq('foo')
    end

    it 'returns a string with a color code' do
      expect(@twig.format_string('foo', :color => :red)).to eq(
        "\e[#{Twig::Display::COLORS[:red]}mfoo\e[0m"
      )
    end

    it 'returns a string with a weight code' do
      expect(@twig.format_string('foo', :weight => :bold)).to eq(
        "\e[#{Twig::Display::WEIGHTS[:bold]}mfoo\e[0m"
      )
    end

    it 'returns a string with a color and weight code 'do
      color_code  = Twig::Display::COLORS[:red]
      weight_code = Twig::Display::WEIGHTS[:bold]

      expect(@twig.format_string('foo', :color => :red, :weight => :bold)).to eq(
        "\e[#{color_code};#{weight_code}mfoo\e[0m"
      )
    end
  end
end
