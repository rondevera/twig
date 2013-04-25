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
      @twig.column('asdfasdf', :width => 8).should == 'asdf... '
    end

    it 'truncates a wide string with an ellipsis' do
      @twig.column('asdfasdfasdf', :width => 8).should == 'asdf... '
    end

    it 'returns a string that spans multiple columns' do
      @twig.column('foo', :width => 16).should == 'foo' + (' ' * 13)
    end

    it 'returns a string that spans multiple columns and is truncated' do
      @twig.column('asdf' * 5, :width => 16).should == 'asdfasdfasdf... '
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
    end

    context 'with custom column widths set' do
      before :each do
        @twig.set_option(:property_width, :foo => 20, :bar => 30)
      end

      it 'returns a default width if a property name is given but it has no custom width' do
        @twig.property_column_width(:baz).should ==
          Twig::Display::DEFAULT_PROPERTY_COLUMN_WIDTH
      end

      it 'returns custom width if a property name is given and it has a custom width' do
        @twig.property_column_width(:foo).should == 20
      end
    end
  end

  describe '#branch_list_headers' do
    before :each do
      Twig::Branch.stub(:all_properties => %w[foo quux])
    end

    it 'returns a string of branch properties and underlines' do
      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      result_lines[0].should == (' ' * date_time_column_width) +
        'foo     ' + (' ' * extra_property_column_width) +
        'quux    ' + (' ' * extra_property_column_width) +
        '  branch' + (' ' * extra_property_column_width)
      result_lines[1].should == (' ' * date_time_column_width) +
        '---     ' + (' ' * extra_property_column_width) +
        '----    ' + (' ' * extra_property_column_width) +
        '  ------' + (' ' * extra_property_column_width)
    end

    it 'sets a header width' do
      @twig.set_option(:property_width, :foo => 4)

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      date_time_column_width      = 35
      extra_property_column_width = 8
      result_lines[0].should == (' ' * date_time_column_width) +
        'foo ' +
        'quux    ' + (' ' * extra_property_column_width) +
        '  branch' + (' ' * extra_property_column_width)
      result_lines[1].should == (' ' * date_time_column_width) +
        '--- ' +
        '----    ' + (' ' * extra_property_column_width) +
        '  ------' + (' ' * extra_property_column_width)
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
      @current_branch_name = 'my-branch'
      Twig::Branch.stub(:all_properties => %w[foo bar])
      @twig.should_receive(:get_branch_property).
        with(anything, 'foo').and_return('foo!')
      @twig.should_receive(:get_branch_property).
        with(anything, 'bar').and_return('bar!')
      @twig.should_receive(:current_branch_name).
        and_return(@current_branch_name)
      @commit_time = Twig::CommitTime.new(Time.now, '')
      @commit_time.should_receive(:to_s).and_return('2000-01-01')
    end

    it 'returns a line for the current branch' do
      indicator     = Twig::Display::CURRENT_BRANCH_INDICATOR
      branch        = Twig::Branch.new('my-branch')
      branch_regexp = /#{Regexp.escape(indicator)}#{Regexp.escape(branch.name)}/
      branch.should_receive(:last_commit_time).and_return(@commit_time)

      result = @twig.branch_list_line(branch)

      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{branch_regexp}/
    end

    it 'returns a line for a branch other than the current branch' do
      branch = Twig::Branch.new('other-branch')
      branch.should_receive(:last_commit_time).and_return(@commit_time)

      result = @twig.branch_list_line(branch)

      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{Regexp.escape(branch.name)}/
    end

    it 'returns a line containing an empty branch property' do
      Twig::Branch.stub(:all_properties => %w[foo bar baz])
      @twig.should_receive(:get_branch_property).
        with(anything, 'baz').and_return(nil)
      branch = Twig::Branch.new('other-branch')
      branch.should_receive(:last_commit_time).and_return(@commit_time)

      result = @twig.branch_list_line(branch)

      empty_indicator = Twig::Display::EMPTY_BRANCH_PROPERTY_INDICATOR
      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{empty_indicator}\s+#{Regexp.escape(branch.name)}/
    end

    it 'changes line break characters to spaces' do
      branch = Twig::Branch.new('my-branch')
      branch.should_receive(:last_commit_time).and_return(@commit_time)
      Twig::Branch.stub(:all_properties => %w[foo bar linebreaks])
      @twig.should_receive(:get_branch_property).
        with(anything, 'linebreaks').and_return("line\r\nbreaks!")

      result = @twig.branch_list_line(branch)

      result.should include('line breaks')
    end

    it 'returns a line with custom column widths' do
      branch = Twig::Branch.new('other-branch')
      branch.should_receive(:last_commit_time).and_return(@commit_time)
      @twig.set_option(:property_width, :foo => 5)

      result = @twig.branch_list_line(branch)

      result.should ==
        '2000-01-01' + (' ' * 25) +
        'foo! ' +
        'bar!' + (' ' * 12) +
        '  ' + branch.name
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
