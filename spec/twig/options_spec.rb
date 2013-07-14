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
      @twig.stub(:all_branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return('branch: test')
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
    end

    it 'reads and sets multiple options' do
      @twig.stub(:all_branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return([
        # Filtering branches:
        'branch:        test',
        'max-days-old:  30.5',
        'except-branch: test-except-branch',
        'only-branch:   test-only-branch',
        'except-foo:    test-except-foo',
        'only-foo:      test-only-foo',

        # Displaying branches:
        'header-style:  green bold',
        'reverse:       true',
        'foo-width:     4',

        # GitHub integration:
        'github-api-uri-prefix: https://github-enterprise.example.com/api/v3',
        'github-uri-prefix:     https://github-enterprise.example.com'
      ].join("\n"))

      # Check preconditions
      @twig.options[:branch].should be_nil
      @twig.options[:github_api_uri_prefix].should be_nil
      @twig.options[:github_uri_prefix].should be_nil
      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should be_nil
      @twig.options[:max_days_old].should be_nil
      @twig.options[:property_except].should be_nil
      @twig.options[:property_only].should be_nil
      @twig.options[:property_width].should be_nil
      @twig.options[:reverse].should be_nil

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
      @twig.options[:github_api_uri_prefix].
        should == 'https://github-enterprise.example.com/api/v3'
      @twig.options[:github_uri_prefix].
        should == 'https://github-enterprise.example.com'
      @twig.options[:header_color].should == :green
      @twig.options[:header_weight].should == :bold
      @twig.options[:max_days_old].should == 30.5
      @twig.options[:property_except].should == {
        :branch => /test-except-branch/,
        :foo    => /test-except-foo/
      }
      @twig.options[:property_only].should == {
        :branch => /test-only-branch/,
        :foo    => /test-only-foo/
      }
      @twig.options[:property_width].should == { :foo => 4 }
      @twig.options[:reverse].should be_true
    end

    it 'skips comments' do
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return([
        '# max-days-old: 40',
        'max-days-old: 30',
        '# max-days-old: 20',
        ' # foo-width: 4'
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
      @twig.options[:property_except].should be_nil
      @twig.options[:property_only].should be_nil

      @twig.read_config_file!

      @twig.options[:property_except].should == { :branch => /test-except/ }
      @twig.options[:property_only].should == { :branch => /test-only/ }
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
        branch_name = 'foo'
        @twig.should_receive(:all_branch_names).and_return(%[foo bar])

        @twig.set_option(:branch, branch_name)

        @twig.options[:branch].should == branch_name
      end

      it 'fails if the branch is unknown' do
        branch_name = 'foo'
        @twig.should_receive(:all_branch_names).and_return([])
        @twig.should_receive(:abort) do |message|
          message.should include(%{branch "#{branch_name}" could not be found})
        end

        @twig.set_option(:branch, branch_name)

        @twig.options[:branch].should be_nil
      end
    end

    it 'sets a :github_api_uri_prefix option' do
      prefix = 'https://github-enterprise.example.com/api/v3'
      @twig.set_option(:github_api_uri_prefix, prefix)
      @twig.options[:github_api_uri_prefix].should == prefix
    end

    it 'sets a :github_uri_prefix option' do
      prefix = 'https://github-enterprise.example.com'
      @twig.set_option(:github_uri_prefix, prefix)
      @twig.options[:github_uri_prefix].should == prefix
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
        value = 'blargh'
        @twig.should_receive(:abort) do |message|
          message.should include("`--max-days-old=#{value}` is invalid")
        end
        @twig.set_option(:max_days_old, value)

        @twig.options[:max_days_old].should be_nil
      end
    end

    it 'sets a :property_except option' do
      @twig.options[:property_except].should be_nil # Precondition
      @twig.set_option(:property_except, :branch => 'unwanted_prefix_')
      @twig.options[:property_except].should == { :branch => /unwanted_prefix_/ }
    end

    it 'sets a :property_only option' do
      @twig.options[:property_only].should be_nil # Precondition
      @twig.set_option(:property_only, :branch => 'important_prefix_')
      @twig.options[:property_only].should == { :branch => /important_prefix_/ }
    end

    it 'sets a :property_width option' do
      width = 10
      @twig.should_receive(:set_property_width_option).with(width)

      @twig.set_option(:property_width, width)
    end

    context 'when setting a :reverse option' do
      before :each do
        @twig.options[:reverse].should be_nil # Precondition
      end

      it 'sets the option to true when input is truthy' do
        input = 'yes'
        Twig::Util.should_receive(:truthy?).with(input).and_call_original

        @twig.set_option(:reverse, input)

        @twig.options[:reverse].should be_true
      end

      it 'sets the option to false when input is not truthy' do
        input = 'blargh'
        Twig::Util.should_receive(:truthy?).with(input).and_call_original

        @twig.set_option(:reverse, input)

        @twig.options[:reverse].should be_false
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

    it 'succeeds at setting color and weight options with extra space between words' do
      @twig.set_header_style_option('red   bold')
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

  describe '#set_property_width_option' do
    before :each do
      @twig.options[:property_width].should be_nil # Precondition
    end

    it 'succeeds' do
      @twig.set_option(:property_width, :foo => '20', :bar => '40')
      @twig.options[:property_width].should == { :foo => 20, :bar => 40 }
    end

    it 'fails if width is not numeric' do
      width = 'blargh'
      @twig.should_receive(:abort) do |message|
        message.should include("`--branch-width=#{width}` is invalid")
        abort # Original behavior, but don't show message in test output
      end

      begin
        @twig.set_option(:property_width, :branch => width)
      rescue SystemExit => exception
      end

      @twig.options[:property_width].should be_nil
    end

    it 'fails if width is below minimum value' do
      min_width = Twig::Options::MIN_PROPERTY_WIDTH
      width     = min_width - 1
      @twig.should_receive(:abort) do |message|
        message.should include("`--x-width=#{width}` is too low. ")
        message.should include("The minimum is #{min_width}.")
        abort
      end

      begin
        @twig.set_option(:property_width, :x => width)
      rescue SystemExit => exception
      end

      @twig.options[:property_width].should be_nil
    end

    it 'fails if width is below width of property name' do
      property_name = :foobarbaz
      width = property_name.to_s.size - 1
      @twig.should_receive(:abort) do |message|
        message.should include("`--#{property_name}-width=#{width}` is too low. ")
        message.should include(%{The minimum is 9 (width of "#{property_name}")})
        abort
      end

      begin
        @twig.set_option(:property_width, property_name => width)
      rescue SystemExit => exception
      end

      @twig.options[:property_width].should be_nil
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
