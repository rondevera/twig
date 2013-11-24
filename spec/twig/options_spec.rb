require 'spec_helper'

describe Twig::Options do
  before :each do
    @twig = Twig.new
  end

  describe '#readable_config_file_path' do
    before :each do
      expect(File).to receive(:expand_path).with(Twig::CONFIG_PATH).
        and_return(Twig::CONFIG_PATH)
    end

    context 'with a config path that exists' do
      before :each do
        expect(File).to receive(:exists?).with(Twig::CONFIG_PATH).and_return(true)
      end

      it 'returns the config path if is readable' do
        path = Twig::CONFIG_PATH
        expect(File).to receive(:readable?).with(path).and_return(true)
        expect($stderr).not_to receive(:puts)

        result = @twig.readable_config_file_path

        expect(result).to eq(path)
      end

      it 'prints a warning and returns nil if the config path is not readable' do
        path = Twig::CONFIG_PATH
        expect(File).to receive(:readable?).with(path).and_return(false)
        expect($stderr).to receive(:puts) do |message|
          expect(message).to include('not readable')
        end

        result = @twig.readable_config_file_path

        expect(result).to be_nil
      end
    end

    context 'with a config path that does not exist' do
      before :each do
        expect(File).to receive(:exists?).with(Twig::CONFIG_PATH).and_return(false)
        expect(File).to receive(:expand_path).with(Twig::DEPRECATED_CONFIG_PATH).
          and_return(Twig::DEPRECATED_CONFIG_PATH)
      end

      it 'prints a deprecation warning and returns the deprecated config path if it exists and is readable' do
        path = Twig::DEPRECATED_CONFIG_PATH
        expect(File).to receive(:exists?).with(path).and_return(true)
        expect(File).to receive(:readable?).with(path).and_return(true)
        expect($stderr).to receive(:puts) do |message|
          expect(message).to match(/^DEPRECATED:/)
          expect(message).to include('Please rename')
          expect(message).not_to include('make it readable')
        end

        result = @twig.readable_config_file_path

        expect(result).to eq(path)
      end

      it 'prints a deprecation warning and returns nil if the deprecated config path exists but is not readable' do
        path = Twig::DEPRECATED_CONFIG_PATH
        expect(File).to receive(:exists?).with(path).and_return(true)
        expect(File).to receive(:readable?).with(path).and_return(false)
        expect($stderr).to receive(:puts) do |message|
          expect(message).to match(/^DEPRECATED:/)
          expect(message).to include('Please rename')
          expect(message).to include('make it readable')
        end

        result = @twig.readable_config_file_path

        expect(result).to be_nil
      end

      it 'returns nil if the deprecated config path does not exist' do
        path = Twig::DEPRECATED_CONFIG_PATH
        expect(File).to receive(:exists?).with(path).and_return(false)

        result = @twig.readable_config_file_path

        expect(result).to be_nil
      end
    end
  end

  describe '#parse_config_file' do
    before :each do
      @file = double('file')
      @path = Twig::CONFIG_PATH
      expect(File).to receive(:open).with(@path).and_yield(@file)
    end

    it 'reads a single option' do
      expect(@file).to receive(:read).and_return('branch: test')
      options = @twig.parse_config_file(@path)
      expect(options).to eq('branch' => 'test')
    end

    it 'reads multiple options' do
      expect(@file).to receive(:read).and_return([
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

      options = @twig.parse_config_file(@path)

      expect(options).to eq(
        'branch'                => 'test',
        'max-days-old'          => '30.5',
        'except-branch'         => 'test-except-branch',
        'only-branch'           => 'test-only-branch',
        'except-foo'            => 'test-except-foo',
        'only-foo'              => 'test-only-foo',
        'header-style'          => 'green bold',
        'reverse'               => 'true',
        'foo-width'             => '4',
        'github-api-uri-prefix' => 'https://github-enterprise.example.com/api/v3',
        'github-uri-prefix'     => 'https://github-enterprise.example.com'
      )
    end

    it 'skips and reports empty keys' do
      expect(@file).to receive(:read).and_return([
        'except-branch: foo',
        ': bar'
      ].join("\n"))
      expect($stderr).to receive(:puts) do |message|
        expect(message).to include('Invalid line')
        expect(message).to include(@path)
      end

      options = @twig.parse_config_file(@path)

      expect(options).to eq('except-branch' => 'foo')
    end

    it 'skips and reports invalid lines' do
      expect(@file).to receive(:read).and_return([
        'except-branch: foo',
        'max-days-old 30'
      ].join("\n"))
      expect($stderr).to receive(:puts) do |message|
        expect(message).to include('Invalid line')
        expect(message).to include(@path)
      end

      options = @twig.parse_config_file(@path)

      expect(options).to eq('except-branch' => 'foo')
    end

    it 'skips comments' do
      expect(@file).to receive(:read).and_return([
        '# max-days-old: 40',
        'max-days-old: 30',
        '# max-days-old: 20',
        ' # foo-width: 4'
      ].join("\n"))
      expect($stderr).not_to receive(:puts)

      options = @twig.parse_config_file(@path)

      expect(options).to eq('max-days-old' => '30')
    end

    it 'skips line breaks' do
      expect(@file).to receive(:read).and_return([
        'except-branch: test-except',
        '',
        'only-branch:   test-only'
      ].join("\n"))
      expect($stderr).not_to receive(:puts)

      options = @twig.parse_config_file(@path)

      expect(options).to eq(
        'except-branch' => 'test-except',
        'only-branch'   => 'test-only'
      )
    end
  end

  describe '#read_config_file!' do
    before :each do
      allow(File).to receive(:expand_path).with(Twig::CONFIG_PATH).
        and_return(Twig::CONFIG_PATH)
    end

    it 'does nothing if there is no readable config file' do
      allow(@twig).to receive(:readable_config_file_path).and_return(nil)
      expect(@twig).not_to receive(:parse_config_file)

      @twig.read_config_file!
    end

    it 'reads and sets a single option' do
      path = Twig::CONFIG_PATH
      allow(@twig).to receive(:all_branch_names) { ['test'] }
      expect(@twig).to receive(:readable_config_file_path).and_return(path)
      expect(@twig).to receive(:parse_config_file).with(path).and_return(
        'branch' => 'test'
      )
      expect(@twig.options[:branch]).to be_nil

      @twig.read_config_file!

      expect(@twig.options[:branch]).to eq('test')
    end

    it 'reads and sets multiple options' do
      path = Twig::CONFIG_PATH
      allow(@twig).to receive(:all_branch_names) { ['test'] }
      expect(@twig).to receive(:readable_config_file_path).and_return(path)
      expect(@twig).to receive(:parse_config_file).with(path).and_return(
        # Filtering branches:
        'branch'        => 'test',
        'max-days-old'  => '30.5',
        'except-branch' => 'test-except-branch',
        'only-branch'   => 'test-only-branch',
        'except-foo'    => 'test-except-foo',
        'only-foo'      => 'test-only-foo',

        # Displaying branches:
        'format'        => 'json',
        'header-style'  => 'green bold',
        'reverse'       => 'true',
        'foo-width'     => '4',

        # GitHub integration:
        'github-api-uri-prefix' => 'https://github-enterprise.example.com/api/v3',
        'github-uri-prefix'     => 'https://github-enterprise.example.com'
      )

      # Check preconditions
      expect(@twig.options[:branch]).to be_nil
      expect(@twig.options[:format]).to be_nil
      expect(@twig.options[:github_api_uri_prefix]).to eq(
        Twig::DEFAULT_GITHUB_API_URI_PREFIX
      )
      expect(@twig.options[:github_uri_prefix]).to eq(
        Twig::DEFAULT_GITHUB_URI_PREFIX
      )
      expect(@twig.options[:header_color]).to eq(Twig::DEFAULT_HEADER_COLOR)
      expect(@twig.options[:header_weight]).to be_nil
      expect(@twig.options[:max_days_old]).to be_nil
      expect(@twig.options[:property_except]).to be_nil
      expect(@twig.options[:property_only]).to be_nil
      expect(@twig.options[:property_width]).to be_nil
      expect(@twig.options[:reverse]).to be_nil

      @twig.read_config_file!

      expect(@twig.options[:branch]).to eq('test')
      expect(@twig.options[:format]).to eq(:json)
      expect(@twig.options[:github_api_uri_prefix]).to eq(
        'https://github-enterprise.example.com/api/v3'
      )
      expect(@twig.options[:github_uri_prefix]).to eq(
        'https://github-enterprise.example.com'
      )
      expect(@twig.options[:header_color]).to eq(:green)
      expect(@twig.options[:header_weight]).to eq(:bold)
      expect(@twig.options[:max_days_old]).to eq(30.5)
      expect(@twig.options[:property_except]).to eq(
        :branch => /test-except-branch/,
        :foo    => /test-except-foo/
      )
      expect(@twig.options[:property_only]).to eq(
        :branch => /test-only-branch/,
        :foo    => /test-only-foo/
      )
      expect(@twig.options[:property_width]).to eq(:foo => 4)
      expect(@twig.options[:reverse]).to be_true
    end
  end

  describe '#set_option' do
    context 'when setting a :branch option' do
      before :each do
        expect(@twig.options[:branch]).to be_nil
      end

      it 'succeeds' do
        branch_name = 'foo'
        expect(@twig).to receive(:all_branch_names).and_return(%[foo bar])

        @twig.set_option(:branch, branch_name)

        expect(@twig.options[:branch]).to eq(branch_name)
      end

      it 'fails if the branch is unknown' do
        branch_name = 'foo'
        expect(@twig).to receive(:all_branch_names).and_return([])
        expect(@twig).to receive(:abort) do |message|
          expect(message).to include(%{branch `#{branch_name}` could not be found})
        end

        @twig.set_option(:branch, branch_name)

        expect(@twig.options[:branch]).to be_nil
      end
    end

    context 'when setting a :format option' do
      it 'succeeds' do
        @twig.set_option(:format, 'json')
        expect(@twig.options[:format]).to eq(:json)
      end

      it 'fails if the option is not :json' do
        value = 'foo'
        expect(@twig).to receive(:abort) do |message|
          expect(message).to include("format `#{value}` is not supported")
        end

        @twig.set_option(:format, value)

        expect(@twig.options[:format]).to be_nil
      end
    end

    it 'sets a :github_api_uri_prefix option' do
      prefix = 'https://github-enterprise.example.com/api/v3'
      @twig.set_option(:github_api_uri_prefix, prefix)
      expect(@twig.options[:github_api_uri_prefix]).to eq(prefix)
    end

    it 'sets a :github_uri_prefix option' do
      prefix = 'https://github-enterprise.example.com'
      @twig.set_option(:github_uri_prefix, prefix)
      expect(@twig.options[:github_uri_prefix]).to eq(prefix)
    end

    it 'sets a :header_style option' do
      style = 'red bold'
      expect(@twig).to receive(:set_header_style_option).with(style)

      @twig.set_option(:header_style, style)
    end

    context 'when setting a :max_days_old option' do
      before :each do
        expect(@twig.options[:max_days_old]).to be_nil
      end

      it 'succeeds' do
        @twig.set_option(:max_days_old, 1)
        expect(@twig.options[:max_days_old]).to eq(1)
      end

      it 'fails if the option is not numeric' do
        value = 'blargh'
        expect(@twig).to receive(:abort) do |message|
          expect(message).to include("`--max-days-old=#{value}` is invalid")
        end
        @twig.set_option(:max_days_old, value)

        expect(@twig.options[:max_days_old]).to be_nil
      end
    end

    it 'sets a :property_except option' do
      expect(@twig.options[:property_except]).to be_nil
      @twig.set_option(:property_except, :branch => 'unwanted_prefix_')
      expect(@twig.options[:property_except]).to eq(:branch => /unwanted_prefix_/)
    end

    it 'sets a :property_only option' do
      expect(@twig.options[:property_only]).to be_nil
      @twig.set_option(:property_only, :branch => 'important_prefix_')
      expect(@twig.options[:property_only]).to eq(:branch => /important_prefix_/)
    end

    it 'sets a :property_width option' do
      width = 10
      expect(@twig).to receive(:set_property_width_option).with(width)

      @twig.set_option(:property_width, width)
    end

    context 'when setting a :reverse option' do
      before :each do
        expect(@twig.options[:reverse]).to be_nil
      end

      it 'sets the option to true when input is truthy' do
        input = 'yes'
        expect(Twig::Util).to receive(:truthy?).with(input).and_call_original

        @twig.set_option(:reverse, input)

        expect(@twig.options[:reverse]).to be_true
      end

      it 'sets the option to false when input is not truthy' do
        input = 'blargh'
        expect(Twig::Util).to receive(:truthy?).with(input).and_call_original

        @twig.set_option(:reverse, input)

        expect(@twig.options[:reverse]).to be_false
      end
    end

    it 'sets an :unset_property option' do
      expect(@twig.options[:unset_property]).to be_nil
      @twig.set_option(:unset_property, 'unwanted_property')
      expect(@twig.options[:unset_property]).to eq('unwanted_property')
    end
  end

  describe '#set_header_style_option' do
    before :each do
      # Preconditions:
      expect(@twig.options[:header_color]).to eq(Twig::DEFAULT_HEADER_COLOR)
      expect(@twig.options[:header_weight]).to be_nil
    end

    it 'succeeds at setting a color option' do
      @twig.set_header_style_option('red')
      expect(@twig.options[:header_color]).to eq(:red)
      expect(@twig.options[:header_weight]).to be_nil
    end

    it 'succeeds at setting a weight option' do
      @twig.set_header_style_option('bold')
      expect(@twig.options[:header_color]).to eq(Twig::DEFAULT_HEADER_COLOR)
      expect(@twig.options[:header_weight]).to eq(:bold)
    end

    it 'succeeds at setting color and weight options, color first' do
      @twig.set_header_style_option('red bold')
      expect(@twig.options[:header_color]).to eq(:red)
      expect(@twig.options[:header_weight]).to eq(:bold)
    end

    it 'succeeds at setting color and weight options, weight first' do
      @twig.set_header_style_option('bold red')
      expect(@twig.options[:header_color]).to eq(:red)
      expect(@twig.options[:header_weight]).to eq(:bold)
    end

    it 'succeeds at setting color and weight options with extra space between words' do
      @twig.set_header_style_option('red   bold')
      expect(@twig.options[:header_color]).to eq(:red)
      expect(@twig.options[:header_weight]).to eq(:bold)
    end

    it 'fails if the one-word option is invalid' do
      style = 'handsofblue' # Two by two...
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--header-style=#{style}` is invalid")
      end
      @twig.set_header_style_option(style)

      expect(@twig.options[:header_color]).to eq(Twig::DEFAULT_HEADER_COLOR)
      expect(@twig.options[:header_weight]).to be_nil
    end

    it 'fails if the color of the two-word option is invalid' do
      style = 'handsofblue bold'
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if the weight of the two-word option is invalid' do
      style = 'red extrabold'
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if there are two colors' do
      style = 'red green'
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end

    it 'fails if there are two weights' do
      style = 'bold bold'
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--header-style=#{style}` is invalid")
      end

      @twig.set_header_style_option(style)
    end
  end

  describe '#set_property_width_option' do
    before :each do
      expect(@twig.options[:property_width]).to be_nil
    end

    it 'succeeds' do
      @twig.set_property_width_option(:foo => '20', :bar => '40')
      expect(@twig.options[:property_width]).to eq(:foo => 20, :bar => 40)
    end

    it 'fails if width is not numeric' do
      width = 'blargh'
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--branch-width=#{width}` is invalid")
        abort # Original behavior, but don't show message in test output
      end

      begin
        @twig.set_property_width_option(:branch => width)
      rescue SystemExit => exception
      end

      expect(@twig.options[:property_width]).to be_nil
    end

    it 'fails if width is below minimum value' do
      min_width = Twig::Options::MIN_PROPERTY_WIDTH
      width     = min_width - 1
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--x-width=#{width}` is too low. ")
        expect(message).to include("The minimum is #{min_width}.")
        abort
      end

      begin
        @twig.set_property_width_option(:x => width)
      rescue SystemExit => exception
      end

      expect(@twig.options[:property_width]).to be_nil
    end

    it 'fails if width is below width of property name' do
      property_name = :foobarbaz
      width = property_name.to_s.size - 1
      expect(@twig).to receive(:abort) do |message|
        expect(message).to include("`--#{property_name}-width=#{width}` is too low. ")
        expect(message).to include(%{The minimum is 9 (width of "#{property_name}")})
        abort
      end

      begin
        @twig.set_property_width_option(property_name => width)
      rescue SystemExit => exception
      end

      expect(@twig.options[:property_width]).to be_nil
    end
  end

  describe '#unset_option' do
    it 'unsets an option' do
      @twig.set_option(:max_days_old, 1)
      expect(@twig.options[:max_days_old]).to eq(1)

      @twig.unset_option(:max_days_old)
      expect(@twig.options[:max_days_old]).to be_nil
    end
  end
end
