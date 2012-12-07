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
      file.should_receive(:read).and_return(%{
        branch: test
      }.gsub(/^\s+/, ''))
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
    end

    it 'reads and sets multiple options' do
      @twig.stub(:branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return(%{
        branch:        test
        except-branch: test-except
        only-branch:   test-only
        max-days-old:  30.5
      }.gsub(/^\s+/, ''))
      @twig.options[:branch].should be_nil # Precondition
      @twig.options[:branch_except].should be_nil # Precondition
      @twig.options[:branch_only].should be_nil # Precondition
      @twig.options[:max_days_old].should be_nil # Precondition

      @twig.read_config_file!

      @twig.options[:branch].should == 'test'
      @twig.options[:branch_except].should == /test-except/
      @twig.options[:branch_only].should == /test-only/
      @twig.options[:max_days_old].should == 30.5
    end

    it 'supports deprecated options' do
      @twig.stub(:branch_names => ['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return(%{
        except-name:  test-except
        only-name:    test-only
      }.gsub(/^\s+/, ''))
      @twig.should_receive(:puts).
        with("\n`--except-name` is deprecated. Please use `--except-branch` instead.\n")
      @twig.should_receive(:puts).
        with("\n`--only-name` is deprecated. Please use `--only-branch` instead.\n")
      @twig.options[:branch_except].should be_nil # Precondition
      @twig.options[:branch_only].should be_nil # Precondition

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

  describe '#unset_option' do
    it 'unsets an option' do
      @twig.set_option(:max_days_old, 1)
      @twig.options[:max_days_old].should == 1 # Precondition

      @twig.unset_option(:max_days_old)
      @twig.options[:max_days_old].should be_nil
    end
  end
end
