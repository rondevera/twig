require 'spec_helper'

describe Twig::Cli do

  describe '#help_description' do
    before :each do
      @twig = Twig.new
    end

    it 'returns short text in a single line' do
      text = 'The quick brown fox.'
      result = @twig.help_description(text, :width => 80)
      result.should == [text]
    end

    it 'returns long text in a string with line breaks' do
      text = 'The quick brown fox jumps over the lazy, lazy dog.'
      result = @twig.help_description(text, :width => 20)
      result.should == [
        'The quick brown fox',
        'jumps over the lazy,',
        'lazy dog.'
      ]
    end

    it 'breaks a long word by max line length' do
      text = 'Thequickbrownfoxjumpsoverthelazydog.'
      result = @twig.help_description(text, :width => 20)
      result.should == [
        'Thequickbrownfoxjump',
        'soverthelazydog.'
      ]
    end

    it 'adds a separator line' do
      text = 'The quick brown fox.'
      result = @twig.help_description(text, :width => 80, :add_separator => true)
      result.should == [text, ' ']
    end
  end

  describe '#help_paragraph' do
    before :each do
      @twig = Twig.new
    end

    it 'returns long text in a paragraph with line breaks' do
      text = Array.new(5) {
        'The quick brown fox jumps over the lazy dog.'
      }.join(' ')

      result = @twig.help_paragraph(text)

      result.should == [
        "The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the",
        "lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps",
        "over the lazy dog. The quick brown fox jumps over the lazy dog."
      ].join("\n")
    end
  end

  describe '#read_cli_options!' do
    before :each do
      @twig = Twig.new
    end

    it 'recognizes `-b` and sets a `:branch` option' do
      @twig.should_receive(:branch_names).and_return(['test'])
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_cli_options!(%w[-b test])

      @twig.options[:branch].should == 'test'
    end

    it 'recognizes `--branch` and sets a `:branch` option' do
      @twig.should_receive(:branch_names).and_return(['test'])
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_cli_options!(%w[--branch test])

      @twig.options[:branch].should == 'test'
    end

    it 'recognizes `--max-days-old` and sets a `:max_days_old` option' do
      @twig.options[:max_days_old].should be_nil # Precondition
      @twig.read_cli_options!(%w[--max-days-old 30])
      @twig.options[:max_days_old].should == 30
    end

    it 'recognizes `--except-branch` and sets a `:property_except` option' do
      @twig.options[:property_except].should be_nil # Precondition
      @twig.read_cli_options!(%w[--except-branch test])
      @twig.options[:property_except].should == { :branch => /test/ }
    end

    it 'recognizes `--only-branch` and sets a `:property_only` option' do
      @twig.options[:property_only].should be_nil # Precondition
      @twig.read_cli_options!(%w[--only-branch test])
      @twig.options[:property_only].should == { :branch => /test/ }
    end

    it 'recognizes `--all` and unsets other options except `:branch`' do
      @twig.set_option(:max_days_old, 30)
      @twig.set_option(:property_except, :branch => /test/)
      @twig.set_option(:property_only,   :branch => /test/)

      @twig.read_cli_options!(['--all'])

      @twig.options[:max_days_old].should be_nil
      @twig.options[:property_except].should be_nil
      @twig.options[:property_only].should be_nil
    end

    it 'recognizes `--unset` and sets an `:unset_property` option' do
      @twig.options[:unset_property].should be_nil # Precondition
      @twig.read_cli_options!(%w[--unset test])
      @twig.options[:unset_property].should == 'test'
    end

    it 'recognizes `--version` and prints the current version' do
      @twig.should_receive(:puts).with(Twig::VERSION)
      @twig.should_receive(:exit)

      @twig.read_cli_options!(['--version'])
    end

    it 'recognizes `--header-style`' do
      @twig.options[:header_color].should == Twig::DEFAULT_HEADER_COLOR
      @twig.options[:header_weight].should be_nil
      @twig.read_cli_options!(['--header-style', 'green bold'])
      @twig.options[:header_color].should == :green
      @twig.options[:header_weight].should == :bold
    end

    it 'handles invalid options' do
      @twig.should_receive(:abort_for_option_exception) do |exception|
        exception.should be_a(OptionParser::InvalidOption)
        exception.message.should include('invalid option: --foo')
      end

      @twig.read_cli_options!(['--foo'])
    end

    it 'handles missing arguments' do
      @twig.should_receive(:abort_for_option_exception) do |exception|
        exception.should be_a(OptionParser::MissingArgument)
        exception.message.should include('missing argument: --branch')
      end

      @twig.read_cli_options!(['--branch'])
    end
  end

  describe '#abort_for_option_exception' do
    before :each do
      @twig = Twig.new
    end

    it 'prints a message and exits' do
      exception = Exception.new('test exception')
      @twig.should_receive(:puts).with(exception.message)
      @twig.should_receive(:puts) do |message|
        message.should include('`twig --help`')
      end
      @twig.should_receive(:exit)

      @twig.abort_for_option_exception(exception)
    end
  end

  describe '#read_cli_args!' do
    before :each do
      @twig = Twig.new
    end

    it 'lists branches' do
      branch_list = %[foo bar]
      @twig.should_receive(:list_branches).and_return(branch_list)
      @twig.should_receive(:puts).with(branch_list)

      @twig.read_cli_args!([])
    end

    context 'running a subcommand' do
      before :each do
        Twig.stub(:run)
        @branch_name = 'test'
        @twig.stub(:current_branch_name => @branch_name)
      end

      it 'recognizes a subcommand' do
        command_path = '/path/to/bin/twig-subcommand'
        Twig.should_receive(:run).with('which twig-subcommand 2>/dev/null').
          and_return(command_path)
        @twig.should_receive(:exec).with(command_path) { exit }

        # Since we're stubbing `exec` (with an expectation), we still need it
        # to exit early like the real implementation. The following handles the
        # exit somewhat gracefully.
        begin
          @twig.read_cli_args!(['subcommand'])
        rescue SystemExit => exception
          expected_exception = exception
        end

        expected_exception.should_not be_nil
        expected_exception.status.should == 0
      end

      it 'does not recognize a subcommand' do
        Twig.should_receive(:run).with('which twig-subcommand 2>/dev/null').and_return('')
        @twig.should_not_receive(:exec)
        @twig.stub(:abort)

        @twig.read_cli_args!(['subcommand'])
      end
    end

    context 'getting properties' do
      before :each do
        @branch_name    = 'test'
        @property_name  = 'foo'
        @property_value = 'bar'
      end

      it 'gets a property for the current branch' do
        @twig.should_receive(:current_branch_name).and_return(@branch_name)
        @twig.should_receive(:get_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([@property_name])
      end

      it 'gets a property for a specified branch' do
        @twig.should_receive(:branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        @twig.should_receive(:get_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([@property_name])
      end
    end

    context 'setting properties' do
      before :each do
        @branch_name    = 'test'
        @property_name  = 'foo'
        @property_value = 'bar'
        @message        = 'Saved.'
      end

      it 'sets a property for the current branch' do
        @twig.should_receive(:current_branch_name).and_return(@branch_name)
        @twig.should_receive(:set_branch_property_for_cli).
          with(@branch_name, @property_name, @property_value)

        @twig.read_cli_args!([@property_name, @property_value])
      end

      it 'sets a property for a specified branch' do
        @twig.should_receive(:branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        @twig.should_receive(:set_branch_property_for_cli).
          with(@branch_name, @property_name, @property_value).
          and_return(@message)

        @twig.read_cli_args!([@property_name, @property_value])
      end
    end

    context 'unsetting properties' do
      before :each do
        @branch_name   = 'test'
        @property_name = 'foo'
        @message       = 'Removed.'
        @twig.set_option(:unset_property, @property_name)
      end

      it 'unsets a property for the current branch' do
        @twig.should_receive(:current_branch_name).and_return(@branch_name)
        @twig.should_receive(:unset_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([])
      end

      it 'unsets a property for a specified branch' do
        @twig.should_receive(:branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        @twig.should_receive(:unset_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([])
      end
    end
  end

  describe '#get_branch_property_for_cli' do
    before :each do
      @twig          = Twig.new
      @branch_name   = 'test'
      @property_name = 'foo'
    end

    it 'gets a property' do
      property_value = 'bar'
      @twig.should_receive(:get_branch_property).
        with(@branch_name, @property_name).and_return(property_value)
      @twig.should_receive(:puts).with(property_value)

      @twig.get_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'shows an error when getting a property that is not set' do
      error_message = 'test error'
      @twig.should_receive(:get_branch_property).
        with(@branch_name, @property_name).and_return(nil)
      Twig::Branch::MissingPropertyError.any_instance.
        stub(:message) { error_message }
      @twig.should_receive(:abort).with(error_message)

      @twig.get_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles ArgumentError when getting an invalid branch property name' do
      bad_property_name = ''
      error_message     = 'test error'
      @twig.should_receive(:get_branch_property).
        with(@branch_name, bad_property_name) do
          raise ArgumentError, error_message
        end
      @twig.should_receive(:abort).with(error_message)

      @twig.get_branch_property_for_cli(@branch_name, bad_property_name)
    end
  end

  describe '#set_branch_property_for_cli' do
    before :each do
      @twig          = Twig.new
      @branch_name   = 'test'
      @property_name = 'foo'
    end

    it 'sets a property for the specified branch' do
      success_message = 'test success'
      property_value  = 'bar'
      @twig.should_receive(:set_branch_property).
        with(@branch_name, @property_name, property_value).
        and_return(success_message)
      @twig.should_receive(:puts).with(success_message)

      @twig.set_branch_property_for_cli(@branch_name, @property_name, property_value)
    end

    it 'handles ArgumentError when unsetting an invalid branch property name' do
      error_message  = 'test error'
      property_value = ''
      @twig.should_receive(:set_branch_property).
        with(@branch_name, @property_name, property_value) do
          raise ArgumentError, error_message
        end
      @twig.should_receive(:abort).with(error_message)

      @twig.set_branch_property_for_cli(@branch_name, @property_name, property_value)
    end

    it 'handles RuntimeError when Git is unable to set a branch property' do
      error_message  = 'test error'
      property_value = ''
      @twig.should_receive(:set_branch_property).
        with(@branch_name, @property_name, property_value) do
          raise RuntimeError, error_message
        end
      @twig.should_receive(:abort).with(error_message)

      @twig.set_branch_property_for_cli(@branch_name, @property_name, property_value)
    end
  end

  describe '#unset_branch_property_for_cli' do
    before :each do
      @twig          = Twig.new
      @branch_name   = 'test'
      @property_name = 'foo'
    end

    it 'unsets a property for the specified branch' do
      success_message = 'test success'
      @twig.should_receive(:unset_branch_property).
        with(@branch_name, @property_name).and_return(success_message)
      @twig.should_receive(:puts).with(success_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles ArgumentError when unsetting an invalid branch property name' do
      error_message = 'test error'
      @twig.should_receive(:unset_branch_property).
        with(@branch_name, @property_name) do
          raise ArgumentError, error_message
        end
      @twig.should_receive(:abort).with(error_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles MissingPropertyError when unsetting a branch property that is not set' do
      error_message = 'test error'
      @twig.should_receive(:unset_branch_property).
        with(@branch_name, @property_name) do
          raise Twig::Branch::MissingPropertyError, error_message
        end
      @twig.should_receive(:abort).with(error_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end
  end

end
