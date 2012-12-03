require 'spec_helper'

describe Twig::Cli do

  describe '#read_cli_options' do
    before :each do
      @twig = Twig.new
    end

    it 'recognizes `-b` and sets a `:branch` option' do
      @twig.should_receive(:branch_names).and_return(%w[test])
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_cli_options(%w[-b test])

      @twig.options[:branch].should == 'test'
    end

    it 'recognizes `--branch` and sets a `:branch` option' do
      @twig.should_receive(:branch_names).and_return(%w[test])
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_cli_options(%w[--branch test])

      @twig.options[:branch].should == 'test'
    end

    it 'recognizes `--max-days-old` and sets a `:max_days_old` option' do
      @twig.options[:max_days_old].should be_nil # Precondition
      @twig.read_cli_options(%w[--max-days-old 30])
      @twig.options[:max_days_old].should == 30
    end

    it 'recognizes `--all` and unsets other options except `:branch`' do
      @twig.set_option(:max_days_old, 30)
      @twig.set_option(:branch_except, /test/)
      @twig.set_option(:branch_only, /test/)

      @twig.read_cli_options(%w[--all])

      @twig.options[:max_days_old].should be_nil
      @twig.options[:branch_except].should be_nil
      @twig.options[:branch_only].should be_nil
    end

    it 'recognizes `--version` and prints the current version' do
      @twig.should_receive(:puts).with(Twig::VERSION)
      @twig.should_receive(:exit)

      @twig.read_cli_options(%w[--version])
    end
  end

  describe '#read_cli_args' do
    before :each do
      @twig = Twig.new
    end

    it 'lists branches' do
      branch_list = %[foo bar]
      @twig.should_receive(:list_branches).and_return(branch_list)
      @twig.should_receive(:puts).with(branch_list)

      @twig.read_cli_args([])
    end

    describe 'running a subcommand' do
      before :each do
        Twig.stub(:run)
        @twig.stub(:current_branch_name => 'test')
        @twig.stub(:puts)
      end

      it 'recognizes a subcommand' do
        command_path = '/path/to/bin/twig-subcommand'
        Twig.should_receive(:run).with('which twig-subcommand').
          and_return(command_path)
        @twig.should_receive(:exec).with(command_path)

        @twig.read_cli_args(['subcommand'])
      end

      it 'does not recognize a subcommand' do
        Twig.should_receive(:run).with('which twig-subcommand').and_return('')
        @twig.should_not_receive(:exec)

        @twig.read_cli_args(['subcommand'])
      end
    end

    describe 'getting properties' do
      before :each do
        @branch_name    = 'test'
        @property_name  = 'foo'
        @property_value = 'bar'
      end

      it 'gets a property for the current branch' do
        @twig.should_receive(:current_branch_name).and_return(@branch_name)
        @twig.should_receive(:get_branch_property).
          with(@branch_name, @property_name).and_return(@property_value)
        @twig.should_receive(:puts).with(@property_value)

        @twig.read_cli_args([@property_name])
      end

      it 'gets a property for a specified branch' do
        @twig.should_receive(:branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        @twig.should_receive(:get_branch_property).
          with(@branch_name, @property_name).and_return(@property_value)
        @twig.should_receive(:puts).with(@property_value)

        @twig.read_cli_args([@property_name])
      end
    end

    describe 'setting properties' do
      before :each do
        @branch_name    = 'test'
        @property_name  = 'foo'
        @property_value = 'bar'
        @message        = 'Saved.'
      end

      it 'sets a property for the current branch' do
        @twig.should_receive(:current_branch_name).and_return(@branch_name)
        @twig.should_receive(:set_branch_property).
          with(@branch_name, @property_name, @property_value).
          and_return(@message)
        @twig.should_receive(:puts).with(@message)

        @twig.read_cli_args([@property_name, @property_value])
      end

      it 'sets a property for a specified branch' do
        @twig.should_receive(:branch_names).and_return([@branch_name])
        @twig.set_option(:branch, @branch_name)
        @twig.should_receive(:set_branch_property).
          with(@branch_name, @property_name, @property_value).
          and_return(@message)
        @twig.should_receive(:puts).with(@message)

        @twig.read_cli_args([@property_name, @property_value])
      end
    end
  end

end
