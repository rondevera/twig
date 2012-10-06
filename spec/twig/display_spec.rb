require 'spec_helper'

describe Twig::Display do
  before :each do
    @twig = Twig.new
  end

  describe '#column' do
    it 'returns a string with an exact fixed width' do
      @twig.column('foo', 1, :width => 8).should == 'foo' + (' ' * 5)
    end

    it 'returns a string that fits a column exactly' do
      @twig.column('asdf', 1, :width => 4).should == 'asdf'
    end

    it 'truncates a wide string with an ellipsis' do
      @twig.column('asdfasdfasdf', 1, :width => 8).should == 'asdf... '
    end

    it 'returns a string that spans multiple columns' do
      @twig.column('foo', 2, :width => 8).should == 'foo' + (' ' * 13)
    end

    it 'returns a string that spans multiple columns and is truncated' do
      @twig.column('asdf' * 5, 2, :width => 8).should == 'asdfasdfasdf... '
    end

    it 'passes options through to `format_string`' do
      format_options = { :color => :red, :weight => :bold }
      @twig.should_receive(:format_string).
        with('foo' + (' ' * 5), format_options)

      @twig.column('foo', 1, format_options)
    end
  end

  describe '#branch_list_headers' do
    it 'returns a string of branch properties and underlines' do
      @twig.should_receive(:all_branch_properties).
        any_number_of_times.and_return(%w[foo quux])

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      column_width = 8
      num_columns_for_date_time = 5
      first_column_width = column_width * num_columns_for_date_time
      result_lines[0].should == (' ' * first_column_width) +
        'foo     ' + (' ' * column_width) +
        'quux    ' + (' ' * column_width) +
        '  branch'
      result_lines[1].should == (' ' * first_column_width) +
        '---     ' + (' ' * column_width) +
        '----    ' + (' ' * column_width) +
        '  ------'
    end
  end

  describe '#branch_list_line' do
    before :each do
      @current_branch = 'my-branch'
      @twig.stub(:all_branch_properties).and_return(['foo', 'bar'])
      @twig.should_receive(:get_branch_property).with(anything, 'foo').and_return('foo!')
      @twig.should_receive(:get_branch_property).with(anything, 'bar').and_return('bar!')
      @twig.should_receive(:current_branch).and_return(@current_branch)
    end

    it 'returns a line for the current branch' do
      indicator     = Twig::Display::CURRENT_BRANCH_INDICATOR
      branch        = 'my-branch'
      branch_regexp = /#{Regexp.escape(indicator)}#{Regexp.escape(branch)}/

      result = @twig.branch_list_line(branch, '2000-01-01')

      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{branch_regexp}/
    end

    it 'returns a line for a branch other than the current branch' do
      branch = 'other-branch'

      result = @twig.branch_list_line(branch, '2000-01-01')

      result.should =~ /2000-01-01\s+foo!\s+bar!\s+#{Regexp.escape(branch)}/
    end
  end

  describe '#format_string' do
    it 'returns a plain string' do
      @twig.format_string('foo', {}).should == 'foo'
    end

    it 'returns a string with a color code' do
      @twig.format_string('foo', :color => :red).
        should == "\033[#{Twig::Display::COLORS[:red]}mfoo\033[0m"
    end

    it 'returns a string with a weight code' do
      @twig.format_string('foo', :weight => :bold).
        should == "\033[#{Twig::Display::WEIGHTS[:bold]}mfoo\033[0m"
    end

    it 'returns a string with a color and weight code 'do
    color_code  = Twig::Display::COLORS[:red]
    weight_code = Twig::Display::WEIGHTS[:bold]

    @twig.format_string('foo', :color => :red, :weight => :bold).
      should == "\033[#{color_code};#{weight_code}mfoo\033[0m"
    end
  end
end
