require 'spec_helper'

describe Twig::Options do
  before :each do
    @twig = Twig.new
  end

  describe '#read_config_file!' do
    before :each do
      File.should_receive(:expand_path).with(Twig::CONFIG_FILE).
        and_return(Twig::CONFIG_FILE)
    end

    it 'reads and sets a single option' do
      @twig.stub(:branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return('branch: test')
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
    end

    it 'reads and sets multiple options' do
      @twig.stub(:branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return([
        'branch:        test',
        'except-branch: test-except',
        'only-branch:   test-only',
        'max-days-old:  30.5',
        'header-style:  green bold'
      ].join("\n"))

      # Check preconditions
      @twig.options[:branch].should be_nil
      @twig.options[:branch_except].should be_nil
      @twig.options[:branch_only].should be_nil
      @twig.options[:max_days_old].should be_nil
      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should be_nil

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
      @twig.options[:branch_except].should == /test-except/
      @twig.options[:branch_only].should == /test-only/
      @twig.options[:max_days_old].should == 30.5
      @twig.options[:header_color].should == :green
      @twig.options[:header_weight].should == :bold
    end

    it 'skips comments' do
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return([
        '# max-days-old: 40',
        'max-days-old: 30',
        '# max-days-old: 20'
      ].join("\n"))
      @twig.options[:max_days_old].should be_nil # Precondition

      @twig.read_config_file!

      @twig.options[:max_days_old].should == 30
    end

    it 'skips line breaks' do
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return([
        'except-branch: test-except',
        '',
        'only-branch:   test-only'
      ].join("\n"))

      # Check preconditions
      @twig.options[:branch_except].should be_nil
      @twig.options[:branch_only].should be_nil

      @twig.read_config_file!

      @twig.options[:branch_except].should == /test-except/
      @twig.options[:branch_only].should == /test-only/
    end

    it 'fails gracefully if the config file is not readable' do
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(false)
      lambda { @twig.read_config_file! }.should_not raise_exception
    end
  end

  describe '#set_option' do
    context 'when setting a :branch option' do
      before :each do
        @twig.options[:branch].should be_nil # Precondition
      end

      it 'succeeds' do
        @twig.should_receive(:branch_names).and_return(%[foo bar])
        @twig.set_option(:branch, 'foo')
        @twig.options[:branch].should == 'foo'
      end

      it 'fails if the branch is unknown' do
        @twig.should_receive(:branch_names).and_return([])
        @twig.should_receive(:abort)

        @twig.set_option(:branch, 'foo')

        @twig.options[:branch].should be_nil
      end
    end

    it 'sets a :branch_except option' do
      @twig.options[:branch_except].should be_nil # Precondition
      @twig.set_option(:branch_except, 'unwanted_prefix_')
      @twig.options[:branch_except].should == /unwanted_prefix_/
    end

    it 'sets a :branch_only option' do
      @twig.options[:branch_only].should be_nil # Precondition
      @twig.set_option(:branch_only, 'important_prefix_')
      @twig.options[:branch_only].should == /important_prefix_/
    end

    it 'sets a :header_style option' do
      style = 'red bold'
      @twig.should_receive(:set_header_style_option).with(style)

      @twig.set_option(:header_style, style)
    end

    context 'when setting a :max_days_old option' do
      before :each do
        @twig.options[:max_days_old].should be_nil # Precondition
      end

      it 'succeeds' do
        @twig.set_option(:max_days_old, 1)
        @twig.options[:max_days_old].should == 1
      end

      it 'fails if the option is not numeric' do
        @twig.should_receive(:abort)
        @twig.set_option(:max_days_old, 'blargh')

        @twig.options[:max_days_old].should be_nil
      end
    end

    it 'sets an :unset_property option' do
      @twig.options[:unset_property].should be_nil # Precondition
      @twig.set_option(:unset_property, 'unwanted_property')
      @twig.options[:unset_property].should == 'unwanted_property'
    end
  end

  describe '#set_header_style_option' do
    before :each do
      # Preconditions:
      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should be_nil
    end

    it 'succeeds at setting a color option' do
      @twig.set_header_style_option('red')
      @twig.options[:header_color].should == :red
      @twig.options[:header_weight].should be_nil
    end

    it 'succeeds at setting a weight option' do
      @twig.set_header_style_option('bold')
      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should == :bold
    end

    it 'succeeds at setting color and weight options, color first' do
      @twig.set_header_style_option('red bold')
      @twig.options[:header_color].should == :red
      @twig.options[:header_weight].should == :bold
    end

    it 'succeeds at setting color and weight options, weight first' do
      @twig.set_header_style_option('bold red')
      @twig.options[:header_color].should == :red
      @twig.options[:header_weight].should == :bold
    end

    it 'fails if the one-word option is invalid' do
      style = 'handsofblue' # Two by two...
      @twig.should_receive(:abort) do |message|
        message.should include("`--header-style=#{style}` is invalid")
      end
      @twig.set_header_style_option(style)

      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should be_nil
    end

    it 'fails if the color of the two-word option is invalid' do
      style = 'handsofblue bold'
      @twig.should_receive(:abort) do |message|
        message.should include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if the weight of the two-word option is invalid' do
      style = 'red extrabold'
      @twig.should_receive(:abort) do |message|
        message.should include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if there are two colors' do
      style = 'red green'
      @twig.should_receive(:abort) do |message|
        message.should include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if there are two weights' do
      style = 'bold bold'
      @twig.should_receive(:abort) do |message|
        message.should include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end
  end

  describe '#unset_option' do
    it 'unsets an option' do
      @twig.set_option(:max_days_old, 1)
      @twig.options[:max_days_old].should == 1 # Precondition

      @twig.unset_option(:max_days_old)
      @twig.options[:max_days_old].should be_nil
    end
  end
end
