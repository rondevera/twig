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
      @twig.column('asdfasdf', 1, :width => 8).should == 'asdf... '
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
      Twig::Branch.stub(:all_properties => %w[foo quux])

      result = @twig.branch_list_headers({})
      result_lines = result.split("\n")

      column_width = 8
      columns_for_date_time = 5
      first_column_width = column_width * columns_for_date_time
      result_lines[0].should == (' ' * first_column_width) +
        'foo     ' + (' ' * column_width) +
        'quux    ' + (' ' * column_width) +
        '  branch' + (' ' * column_width)
      result_lines[1].should == (' ' * first_column_width) +
        '---     ' + (' ' * column_width) +
        '----    ' + (' ' * column_width) +
        '  ------' + (' ' * column_width)
    end

    it 'returns colorful headers' do
      Twig::Branch.stub(:all_properties => %w[foo quux])
      result = @twig.branch_list_headers({ :header_color => :red, :header_weight => :bold })
      header_line = result.split("\n").first
      color, weight = Twig::Display::COLORS[:red], Twig::Display::WEIGHTS[:bold]
      header_line.gsub(/\s/, '').should ==
        "\e[#{color};#{weight}mfoo\e[0m\e[#{color};#{weight}mquux" <<
        "\e[0m\e[#{color};#{weight}mbranch\e[0m"
      result = @twig.branch_list_headers({ :header_color => :green })
      header_line = result.split("\n").first
      color = Twig::Display::COLORS[:green]
      header_line.gsub(/\s/, '').should ==
        "\e[#{color}mfoo\e[0m\e[#{color}mquux\e[0m\e[#{color}mbranch\e[0m"
      result = @twig.branch_list_headers({ :header_weight => :bold })
      header_line = result.split("\n").first
      weight = Twig::Display::WEIGHTS[:bold]
      header_line.gsub(/\s/, '').should ==
        "\e[#{weight}mfoo\e[0m\e[#{weight}mquux\e[0m\e[#{weight}mbranch\e[0m"
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

    it 'changes line break characters to spaces' do
      branch = Twig::Branch.new('my-branch')
      branch.should_receive(:last_commit_time).and_return(@commit_time)
      Twig::Branch.stub(:all_properties => %w[foo bar linebreaks])
      @twig.should_receive(:get_branch_property).
        with(anything, 'linebreaks').and_return("line\r\nbreaks!")

      result = @twig.branch_list_line(branch)

      result.should include('line breaks')
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
