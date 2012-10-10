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

    describe 'with a warm `#branch_names` cache' do
      before :each do
        branch_refs = %w[
          refs/heads/bar
          refs/heads/baz
          refs/heads/foo
        ]
        Twig.should_receive(:run).
          with('git for-each-ref refs/heads/ --format="%(refname)"').
          and_return(branch_refs.join("\n"))
        @twig.branch_names.should == %w[bar baz foo] # Precondition; warm cache
      end

      it 'recognizes `--only-name` and sets a `:name_only` option' do
        @twig.options[:name_only].should be_nil # Precondition

        @twig.read_cli_options(%w[--only-name ba])

        @twig.options[:name_only].should == /ba/
        @twig.branch_names.should == %w[bar baz]
      end

      it 'recognizes `--except-name` and sets a `:name_except` option' do
        @twig.options[:name_except].should be_nil # Precondition

        @twig.read_cli_options(%w[--except-name ba])

        @twig.options[:name_except].should == /ba/
        @twig.branch_names.should == %w[foo]
      end
    end

    it 'recognizes `--all` and unsets other options except `:branch`' do
      @twig.set_option(:max_days_old, 30)
      @twig.set_option(:name_except, /test/)
      @twig.set_option(:name_only, /test/)

      @twig.read_cli_options(%w[--all])

      @twig.options[:max_days_old].should be_nil
      @twig.options[:name_except].should be_nil
      @twig.options[:name_only].should be_nil
    end

    it 'recognizes `--version` and prints the current version' do
      @twig.should_receive(:puts).with(Twig::VERSION)
      @twig.should_receive(:exit)

      @twig.read_cli_options(%w[--version])
    end
  end
end
