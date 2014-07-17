require 'spec_helper'

describe Twig::Cli do

  describe '.prompt_with_choices' do
    it 'prints a prompt with the given choices' do
      stdout_orig = $stdout
      stdout_test = StringIO.new
      $stdout     = stdout_test
      prompt      = 'What does the fox say?'
      choices     = [
        'Ring-ding-ding-ding-dingeringeding!',
        'Wa-pa-pa-pa-pa-pa-pow!',
        'Hatee-hatee-hatee-ho!',
        'Joff-tchoff-tchoffo-tchoffo-tchoff!'
      ]
      expect($stdin).to receive(:gets).and_return('4')

      result = Twig::Cli.prompt_with_choices(prompt, choices)

      $stdout = stdout_orig
      expect(stdout_test.string).to eq(
        prompt + "\n" +
        "  1. #{choices[0]}\n" +
        "  2. #{choices[1]}\n" +
        "  3. #{choices[2]}\n" +
        "  4. #{choices[3]}\n" +
        '> '
      )
      expect(result).to eq(choices[3])
    end

    it 'requires at least two choices' do
      expect {
        Twig::Cli.prompt_with_choices(
          'What does the fox say?',
          ['Ring-ding-ding-ding-dingeringeding!']
        )
      }.to raise_exception(ArgumentError)
    end
  end

  describe '#run_pager' do
    before :each do
      @twig = Twig.new
      allow(Twig::System).to receive(:windows?) { false }
      allow($stdout).to receive(:tty?) { true }
      allow($stderr).to receive(:tty?) { true }
    end

    it 'turns the current process into a `less` pager' do
      allow(Kernel).to receive(:fork) { true }
      expect(@twig).to receive(:exec).with('less')

      @twig.run_pager
    end

    it 'turns the current process into a custom pager' do
      allow(Kernel).to receive(:fork) { true }
      pager = 'arbitrary'
      expect(ENV).to receive(:[]).with('PAGER').and_return(pager)
      expect(@twig).to receive(:exec).with(pager)

      @twig.run_pager
    end

    it 'reopens original stdout and stderr if unable to fork' do
      allow(Kernel).to receive(:fork) { false }
      expect($stdout).to receive(:reopen)
      expect($stderr).to receive(:reopen)
      expect($stdin).not_to receive(:reopen)

      @twig.run_pager
    end

    it 'does nothing if running on Windows' do
      expect(Twig::System).to receive(:windows?).and_return(true)
      expect(IO).not_to receive(:pipe)

      @twig.run_pager
    end

    it 'does nothing if stdout is not running on a terminal device' do
      allow($stdout).to receive(:tty?) { false }
      expect(IO).not_to receive(:pipe)

      @twig.run_pager
    end

    it 'does nothing if `Kernel.fork` is not supported' do
      allow(Kernel).to receive(:respond_to?).with(:fork) { false }
      expect(IO).not_to receive(:pipe)

      @twig.run_pager
    end
  end

  describe '#read_cli_options!' do
    before :each do
      @twig = Twig.new
      allow(@twig).to receive(:run_pager)
    end

    it 'recognizes `--unset` and sets an `:unset_property` option' do
      expect(@twig.options[:unset_property]).to be_nil
      @twig.read_cli_options!(%w[--unset test])
      expect(@twig.options[:unset_property]).to eq('test')
    end

    it 'recognizes `--help` and prints the help content' do
      help_lines = []
      allow(@twig).to receive(:puts) { |message| help_lines << message.strip }
      expect(@twig).to receive(:exit)

      @twig.read_cli_options!(['--help'])

      expect(help_lines).to include("Twig v#{Twig::VERSION}")
      expect(help_lines).to include('http://rondevera.github.io/twig/')
    end

    it 'recognizes `--version` and prints the current version' do
      expect(@twig).to receive(:puts).with(Twig::VERSION)
      expect(@twig).to receive(:exit)

      @twig.read_cli_options!(['--version'])
    end

    it 'recognizes `-b` and sets a `:branch` option' do
      expect(Twig::Branch).to receive(:all_branch_names).and_return(['test'])
      expect(@twig.options[:branch]).to be_nil

      @twig.read_cli_options!(%w[-b test])

      expect(@twig.options[:branch]).to eq('test')
    end

    it 'recognizes `--branch` and sets a `:branch` option' do
      expect(Twig::Branch).to receive(:all_branch_names).and_return(['test'])
      expect(@twig.options[:branch]).to be_nil

      @twig.read_cli_options!(%w[--branch test])

      expect(@twig.options[:branch]).to eq('test')
    end

    it 'recognizes `--max-days-old` and sets a `:max_days_old` option' do
      expect(@twig.options[:max_days_old]).to be_nil
      @twig.read_cli_options!(%w[--max-days-old 30])
      expect(@twig.options[:max_days_old]).to eq(30)
    end

    it 'recognizes `--except-branch` and sets a `:property_except` option' do
      expect(@twig.options[:property_except]).to be_nil
      @twig.read_cli_options!(%w[--except-branch test])
      expect(@twig.options[:property_except]).to eq(:branch => /test/)
    end

    it 'recognizes `--only-branch` and sets a `:property_only` option' do
      expect(@twig.options[:property_only]).to be_nil
      @twig.read_cli_options!(%w[--only-branch test])
      expect(@twig.options[:property_only]).to eq(:branch => /test/)
    end

    context 'with custom property "only" filtering' do
      before :each do
        expect(@twig.options[:property_only]).to be_nil
      end

      it 'recognizes `--only-<property>` and sets a `:property_only` option' do
        allow(Twig::Branch).to receive(:all_property_names) { %w[foo] }
        @twig.read_cli_options!(%w[--only-foo test])
        expect(@twig.options[:property_only]).to eq(:foo => /test/)
      end

      it 'recognizes `--only-branch` and `--only-<property>` together' do
        allow(Twig::Branch).to receive(:all_property_names) { %w[foo] }

        @twig.read_cli_options!(%w[--only-branch test --only-foo bar])

        expect(@twig.options[:property_only]).to eq(
          :branch => /test/,
          :foo    => /bar/
        )
      end

      it 'does not recognize `--only-<property>` for a missing property' do
        property_name = 'foo'
        expect(Twig::Branch.all_property_names).not_to include(property_name)
        allow(@twig).to receive(:puts)

        expect {
          @twig.read_cli_options!(["--only-#{property_name}", 'test'])
        }.to raise_exception { |exception|
          expect(exception).to be_a(SystemExit)
          expect(exception.status).to eq(1)
        }

        expect(@twig.options[:property_only]).to be_nil
      end
    end

    context 'with custom property "except" filtering' do
      before :each do
        expect(@twig.options[:property_except]).to be_nil
      end

      it 'recognizes `--except-<property>` and sets a `:property_except` option' do
        allow(Twig::Branch).to receive(:all_property_names) { %w[foo] }
        @twig.read_cli_options!(%w[--except-foo test])
        expect(@twig.options[:property_except]).to eq(:foo => /test/)
      end

      it 'recognizes `--except-branch` and `--except-<property>` together' do
        allow(Twig::Branch).to receive(:all_property_names) { %w[foo] }

        @twig.read_cli_options!(%w[--except-branch test --except-foo bar])

        expect(@twig.options[:property_except]).to eq(
          :branch => /test/,
          :foo    => /bar/
        )
      end

      it 'does not recognize `--except-<property>` for a missing property' do
        property_name = 'foo'
        expect(Twig::Branch.all_property_names).not_to include(property_name)
        allow(@twig).to receive(:puts)

        expect {
          @twig.read_cli_options!(["--except-#{property_name}", 'test'])
        }.to raise_exception { |exception|
          expect(exception).to be_a(SystemExit)
          expect(exception.status).to eq(1)
        }

        expect(@twig.options[:property_except]).to be_nil
      end
    end

    it 'recognizes `--format` and sets a `:format` option' do
      expect(@twig.options[:format]).to be_nil
      @twig.read_cli_options!(%w[--format json])
      expect(@twig.options[:format]).to eq(:json)
    end

    it 'recognizes `--all` and unsets other options except `:branch`' do
      @twig.set_option(:max_days_old, 30)
      @twig.set_option(:property_except, :branch => /test/)
      @twig.set_option(:property_only,   :branch => /test/)

      @twig.read_cli_options!(['--all'])

      expect(@twig.options[:max_days_old]).to be_nil
      expect(@twig.options[:property_except]).to be_nil
      expect(@twig.options[:property_only]).to be_nil
    end

    it 'recognizes `--branch-width`' do
      expect(@twig.options[:property_width]).to be_nil
      expect(@twig).to receive(:set_option).with(:property_width, :branch => '10')

      @twig.read_cli_options!(%w[--branch-width 10])
    end

    it 'recognizes `--<property>-width`' do
      allow(Twig::Branch).to receive(:all_property_names) { %w[foo] }
      expect(@twig.options[:property_width]).to be_nil
      expect(@twig).to receive(:set_option).with(:property_width, :foo => '10')

      @twig.read_cli_options!(%w[--foo-width 10])
    end

    it 'recognizes `--only-property`' do
      expect(@twig.options[:property_only_name]).to be_nil
      @twig.read_cli_options!(%w[--only-property foo])
      expect(@twig.options[:property_only_name]).to eq(/foo/)
    end

    it 'recognizes `--except-property`' do
      expect(@twig.options[:property_except_name]).to be_nil
      @twig.read_cli_options!(%w[--except-property foo])
      expect(@twig.options[:property_except_name]).to eq(/foo/)
    end

    it 'recognizes `--header-style`' do
      expect(@twig.options[:header_color]).to eq(Twig::DEFAULT_HEADER_COLOR)
      expect(@twig.options[:header_weight]).to be_nil
      @twig.read_cli_options!(['--header-style', 'green bold'])
      expect(@twig.options[:header_color]).to eq(:green)
      expect(@twig.options[:header_weight]).to eq(:bold)
    end

    it 'recognizes `--reverse`' do
      expect(@twig.options[:reverse]).to be_nil
      @twig.read_cli_options!(['--reverse'])
      expect(@twig.options[:reverse]).to eql(true)
    end

    it 'recognizes `--github-api-uri-prefix`' do
      expect(@twig.options[:github_api_uri_prefix]).to eq(Twig::DEFAULT_GITHUB_API_URI_PREFIX)
      prefix = 'https://github-enterprise.example.com/api/v3'

      @twig.read_cli_options!(['--github-api-uri-prefix', prefix])

      expect(@twig.options[:github_api_uri_prefix]).to eq(prefix)
    end

    it 'recognizes `--github-uri-prefix`' do
      expect(@twig.options[:github_uri_prefix]).to eq(Twig::DEFAULT_GITHUB_URI_PREFIX)
      prefix = 'https://github-enterprise.example.com'

      @twig.read_cli_options!(['--github-uri-prefix', prefix])

      expect(@twig.options[:github_uri_prefix]).to eq(prefix)
    end

    it 'handles invalid options' do
      expect(@twig).to receive(:abort_for_option_exception) do |exception|
        expect(exception).to be_a(OptionParser::InvalidOption)
        expect(exception.message).to include('invalid option: --foo')
      end

      @twig.read_cli_options!(['--foo'])
    end

    it 'handles missing arguments' do
      expect(@twig).to receive(:abort_for_option_exception) do |exception|
        expect(exception).to be_a(OptionParser::MissingArgument)
        expect(exception.message).to include('missing argument: --branch')
      end

      @twig.read_cli_options!(['--branch'])
    end
  end

  describe '#abort_for_option_exception' do
    before :each do
      @twig = Twig.new
    end

    it 'prints a message and aborts' do
      expect(@twig).to receive(:puts) do |message|
        expect(message).to include('`twig help`')
      end

      expect {
        exception = Exception.new('test exception')
        @twig.abort_for_option_exception(exception)
      }.to raise_exception { |exception|
        expect(exception).to be_a(SystemExit)
        expect(exception.status).to eq(1)
      }
    end
  end

  describe '#read_cli_args!' do
    before :each do
      @twig = Twig.new
    end

    it 'checks for and executes a subcommand if there are any args' do
      expect(Twig::Subcommands).to receive(:exec_subcommand_if_any).with(['foo']) { exit }

      expect {
        @twig.read_cli_args!(['foo'])
      }.to raise_exception { |exception|
        expect(exception).to be_a(SystemExit)
        expect(exception.status).to eq(0)
      }
    end

    it 'does not check for a subcommand if there are no args' do
      branch_list = %[foo bar]
      expect(Twig::Subcommands).not_to receive(:exec_subcommand_if_any)
      allow(@twig).to receive(:list_branches).and_return(branch_list)
      allow(@twig).to receive(:puts).with(branch_list)

      @twig.read_cli_args!([])
    end

    it 'lists branches' do
      branch_list = %[foo bar]
      expect(@twig).to receive(:list_branches).and_return(branch_list)
      expect(@twig).to receive(:puts).with(branch_list)

      @twig.read_cli_args!([])
    end

    it 'prints branch properties as JSON' do
      branches_json = {
        'branch1' => { 'last-commit-time' => '2000-01-01' },
        'branch2' => { 'last-commit-time' => '2000-01-01' }
      }.to_json
      expect(@twig).to receive(:branches_json).and_return(branches_json)
      expect(@twig).to receive(:puts).with(branches_json)

      @twig.read_cli_args!(%w[--format json])
    end

    context 'getting properties' do
      before :each do
        @branch_name    = 'test'
        @property_name  = 'foo'
        @property_value = 'bar'
      end

      it 'gets a property for the current branch' do
        expect(@twig).to receive(:current_branch_name).and_return(@branch_name)
        expect(@twig).to receive(:get_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([@property_name])
      end

      it 'gets a property for a specified branch' do
        expect(Twig::Branch).to receive(:all_branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        expect(@twig).to receive(:get_branch_property_for_cli).
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
        expect(@twig).to receive(:current_branch_name).and_return(@branch_name)
        expect(@twig).to receive(:set_branch_property_for_cli).
          with(@branch_name, @property_name, @property_value)

        @twig.read_cli_args!([@property_name, @property_value])
      end

      it 'sets a property for a specified branch' do
        expect(Twig::Branch).to receive(:all_branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        expect(@twig).to receive(:set_branch_property_for_cli).
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
        expect(@twig).to receive(:current_branch_name).and_return(@branch_name)
        expect(@twig).to receive(:unset_branch_property_for_cli).
          with(@branch_name, @property_name)

        @twig.read_cli_args!([])
      end

      it 'unsets a property for a specified branch' do
        expect(Twig::Branch).to receive(:all_branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        expect(@twig).to receive(:unset_branch_property_for_cli).
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
      expect(@twig).to receive(:get_branch_property).
        with(@branch_name, @property_name).and_return(property_value)
      expect(@twig).to receive(:puts).with(property_value)

      @twig.get_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'shows an error when getting a property that is not set' do
      error_message = 'test error'
      expect(@twig).to receive(:get_branch_property).
        with(@branch_name, @property_name).and_return(nil)
      allow_any_instance_of(Twig::Branch::MissingPropertyError).
        to receive(:message) { error_message }
      expect(@twig).to receive(:abort).with(error_message)

      @twig.get_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles ArgumentError when getting an invalid branch property name' do
      bad_property_name = ''
      error_message     = 'test error'
      expect(@twig).to receive(:get_branch_property).
        with(@branch_name, bad_property_name) do
          raise ArgumentError, error_message
        end
      expect(@twig).to receive(:abort).with(error_message)

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
      expect(@twig).to receive(:set_branch_property).
        with(@branch_name, @property_name, property_value).
        and_return(success_message)
      expect(@twig).to receive(:puts).with(success_message)

      @twig.set_branch_property_for_cli(@branch_name, @property_name, property_value)
    end

    it 'handles ArgumentError when unsetting an invalid branch property name' do
      error_message  = 'test error'
      property_value = ''
      expect(@twig).to receive(:set_branch_property).
        with(@branch_name, @property_name, property_value) do
          raise ArgumentError, error_message
        end
      expect(@twig).to receive(:abort).with(error_message)

      @twig.set_branch_property_for_cli(@branch_name, @property_name, property_value)
    end

    it 'handles RuntimeError when Git is unable to set a branch property' do
      error_message  = 'test error'
      property_value = ''
      expect(@twig).to receive(:set_branch_property).
        with(@branch_name, @property_name, property_value) do
          raise RuntimeError, error_message
        end
      expect(@twig).to receive(:abort).with(error_message)

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
      expect(@twig).to receive(:unset_branch_property).
        with(@branch_name, @property_name).and_return(success_message)
      expect(@twig).to receive(:puts).with(success_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles ArgumentError when unsetting an invalid branch property name' do
      error_message = 'test error'
      expect(@twig).to receive(:unset_branch_property).
        with(@branch_name, @property_name) do
          raise ArgumentError, error_message
        end
      expect(@twig).to receive(:abort).with(error_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end

    it 'handles MissingPropertyError when unsetting a branch property that is not set' do
      error_message = 'test error'
      expect(@twig).to receive(:unset_branch_property).
        with(@branch_name, @property_name) do
          raise Twig::Branch::MissingPropertyError, error_message
        end
      expect(@twig).to receive(:abort).with(error_message)

      @twig.unset_branch_property_for_cli(@branch_name, @property_name)
    end
  end

end
