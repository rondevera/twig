require 'spec_helper'

describe Twig::Display do
  before :each do
    @twig = Twig.new
  end

  describe '#column' do
    it 'returns a string with an exact fixed width' do
      @twig.column('foo', :width => 8).should == 'foo' + (' ' * 5)
    end

    it 'returns a string that fits a column exactly' do
      @twig.column('asdfasdf', :width => 8).should == 'asdfasdf'
    end

    it 'truncates a wide string with an ellipsis' do
      @twig.column('asdfasdfasdf', :width => 8).should == 'asdfa...'
    end

    it 'passes options through to `format_string`' do
      format_options = { :color => :red, :weight => :bold }
      @twig.should_receive(:format_string).
        with('foo' + (' ' * 5), format_options)

      @twig.column('foo', format_options)
    end
  end

  describe '#property_column_width' do
    it 'returns a default width if no property name is given' do
      @twig.property_column_width.should ==
        Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
    end

    context 'with no custom column widths set' do
      before :each do
        @twig.options[:property_width].should be_nil
      end

      it 'returns a default width if a property name is given' do
        @twig.property_column_width(:foo).should ==
          Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
      end

      it 'returns a default width if :branch is given' do
        @twig.property_column_width(:branch).should ==
          Twig::Display::DEFAULT_BRANCH_COLUMN_WIDTH
      end
    end

    context 'with custom column widths set' do
      it 'returns a default width if a property name is given but it has no custom width' do
        @twig.property_column_width(:baz).should ==
          Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
      end

      it 'returns a custom width if a property name is given and it has a custom width' do
        @twig.set_option(:property_width, :foo => 20)
        @twig.property_column_width(:foo).should == 20
      end

      it 'returns a default width if :branch is given but it has no custom width' do
        @twig.property_column_width(:branch).should ==
          Twig::Display::DEFAULT_BRANCH_COLUMN_WIDTH
      end

      it 'returns a custom width if :branch is given but it has no custom width' do
        @twig.set_option(:property_width, :branch => 20)
        @twig.property_column_width(:branch).should == 20
      end
    end
  end

  describe '#branch_list_headers' do
    before :each do
      Twig::Branch.stub(:all_property_names => %w[foo quux])
    end

    it 'returns a string of branch properties and underlines' do
      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      column_gutter = @twig.column_gutter
      result_lines[0].should == (' ' * date_time_column_width) + column_gutter +
        'foo     ' + (' ' * extra_property_column_width) + column_gutter +
        'quux    ' + (' ' * extra_property_column_width) + column_gutter +
        '  branch'
      result_lines[1].should == (' ' * date_time_column_width) + column_gutter +
        '---     ' + (' ' * extra_property_column_width) + column_gutter +
        '----    ' + (' ' * extra_property_column_width) + column_gutter +
        '  ------'
    end

    it 'sets a header width' do
      @twig.set_option(:property_width, :foo => 4)

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      column_gutter = @twig.column_gutter
      result_lines[0].should == (' ' * date_time_column_width) + column_gutter +
        'foo '     + column_gutter +
        'quux    ' + (' ' * extra_property_column_width) + column_gutter +
        '  branch'
      result_lines[1].should == (' ' * date_time_column_width) + column_gutter +
        '--- '     + column_gutter +
        '----    ' + (' ' * extra_property_column_width) + column_gutter +
        '  ------'
    end

    it 'sets a header color' do
      result = @twig.branch_list_headers({ :header_color => :green })
      header_line = result.split("\n").first
      color = Twig::Display::COLORS[:green]
      header_line.gsub(/\s/, '').should ==
        "\e[#{color}mfoo\e[0m" <<
        "\e[#{color}mquux\e[0m" <<
        "\e[#{color}mbranch\e[0m"
    end

    it 'sets a header weight' do
      result = @twig.branch_list_headers({ :header_weight => :bold })
      header_line = result.split("\n").first
      weight = Twig::Display::WEIGHTS[:bold]
      header_line.gsub(/\s/, '').should ==
        "\e[#{weight}mfoo\e[0m" <<
        "\e[#{weight}mquux\e[0m" <<
        "\e[#{weight}mbranch\e[0m"
    end

    it 'sets a header color and weight' do
      result = @twig.branch_list_headers({ :header_color => :red, :header_weight => :bold })
      header_line = result.split("\n").first
      color, weight = Twig::Display::COLORS[:red], Twig::Display::WEIGHTS[:bold]
      header_line.gsub(/\s/, '').should ==
        "\e[#{color};#{weight}mfoo\e[0m" <<
        "\e[#{color};#{weight}mquux\e[0m" <<
        "\e[#{color};#{weight}mbranch\e[0m"
    end
  end

  describe '#branch_list_line' do
    before :each do
      @current_branch = Twig::Branch.new('my-branch')
      @other_branch   = Twig::Branch.new('other-branch')
      @twig.should_receive(:current_branch_name).and_return(@current_branch.name)
      Twig::Branch.stub(:all_property_names => %w[foo bar])
      @current_branch.stub(:get_properties => {
        'foo' => 'foo!',
        'bar' => 'bar!'
      })
      @other_branch.stub(:get_properties => {
        'foo' => 'foo!',
        'bar' => 'bar!'
      })
      commit_time = Twig::CommitTime.new(Time.now, '')
      commit_time.should_receive(:to_s).and_return('2000-01-01')
      @current_branch.stub(:last_commit_time => commit_time)
      @other_branch.stub(:last_commit_time => commit_time)
    end

    it 'returns a line for the current branch' do
      indicator     = Twig::Display::CURRENT_BRANCH_INDICATOR
      branch        = @current_branch
      branch_regexp = /#{Regexp.escape(indicator)}#{Regexp.escape(branch.name)}/

      result = @twig.branch_list_line(branch)

      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{branch_regexp}/
    end

    it 'returns a line for a branch other than the current branch' do
      branch = @other_branch
      result = @twig.branch_list_line(branch)
      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{Regexp.escape(branch.name)}/
    end

    it 'returns a line containing an empty branch property' do
      Twig::Branch.should_receive(:all_property_names).and_return(%w[foo bar baz])
      branch = @other_branch

      result = @twig.branch_list_line(branch)

      empty_indicator = Twig::Display::EMPTY_BRANCH_PROPERTY_INDICATOR
      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{empty_indicator}\s+#{Regexp.escape(branch.name)}/
    end

    it 'changes line break characters to spaces' do
      branch = @current_branch
      property_names = %w[foo bar linebreaks]
      branch.should_receive(:get_properties).with(property_names).and_return(
        'foo' => 'foo!',
        'bar' => 'bar!',
        'linebreaks' => "line\r\nbreaks!"
      )
      Twig::Branch.should_receive(:all_property_names).and_return(property_names)

      result = @twig.branch_list_line(branch)

      result.should include('line breaks')
    end

    it 'returns a line with custom column widths' do
      branch = @other_branch
      @twig.set_option(:property_width, :foo => 5)

      result = @twig.branch_list_line(branch)

      column_gutter = @twig.column_gutter
      result.should ==
        '2000-01-01' + (' ' * 25) + column_gutter +
        'foo! ' + column_gutter +
        'bar!' + (' ' * 12) + column_gutter +
        '  ' + branch.name
    end

    context 'with a custom width for the branch column' do
      before :each do
        @twig.set_option(:property_width, :branch => 8)
      end

      it 'returns a line for the current branch' do
        indicator     = Twig::Display::CURRENT_BRANCH_INDICATOR
        branch        = @current_branch
        branch_regexp = /#{Regexp.escape(indicator)}#{Regexp.escape(branch.name)}/

        result = @twig.branch_list_line(branch)
        unformatted_result = @twig.unformat_string(result)

        column_gutter = @twig.column_gutter
        unformatted_result.should ==
          '2000-01-01' + (' ' * 25) + column_gutter +
          'foo!' + (' ' * 12) + column_gutter +
          'bar!' + (' ' * 12) + column_gutter +
          indicator + 'my-br...'
      end

      it 'returns a line for a branch other than the current branch' do
        branch = @other_branch

        result = @twig.branch_list_line(branch)

        column_gutter = @twig.column_gutter
        result.should ==
          '2000-01-01' + (' ' * 25) + column_gutter +
          'foo!' + (' ' * 12) + column_gutter +
          'bar!' + (' ' * 12) + column_gutter +
          '  ' + 'other...'
      end
    end
  end

  describe '#format_string' do
    it 'returns a plain string' do
      @twig.format_string('foo', {}).should == 'foo'
    end

    it 'returns a string with a color code' do
      @twig.format_string('foo', :color => :red).
        should == "\e[#{Twig::Display::COLORS[:red]}mfoo\e[0m"
    end

    it 'returns a string with a weight code' do
      @twig.format_string('foo', :weight => :bold).
        should == "\e[#{Twig::Display::WEIGHTS[:bold]}mfoo\e[0m"
    end

    it 'returns a string with a color and weight code 'do
    color_code  = Twig::Display::COLORS[:red]
    weight_code = Twig::Display::WEIGHTS[:bold]

    @twig.format_string('foo', :color => :red, :weight => :bold).
      should == "\e[#{color_code};#{weight_code}mfoo\e[0m"
    end
  end

  describe '#unformat_string' do
    it 'unformats a plain text string' do
      string = 'foo'
      @twig.unformat_string(string).should == string
    end

    it 'unformats a string with color' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :color => :red)
      formatted_string.size.should > 3 # Precondition

      @twig.unformat_string(formatted_string).should == string
    end

    it 'unformats a string with weight' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :weight => :bold)
      formatted_string.size.should > 3 # Precondition

      @twig.unformat_string(formatted_string).should == string
    end

    it 'unformats a string with color and weight' do
      string = 'foo'
      formatted_string = @twig.format_string(string, :color => :red, :weight => :bold)
      formatted_string.size.should > 3 # Precondition

      @twig.unformat_string(formatted_string).should == string
    end
  end
end
