require 'spec_helper'

describe Twig::Options do
  before :each do
    @twig = Twig.new
  end

  describe '#read_config_file' do
    before :each do
      File.should_receive(:expand_path).with(Twig::CONFIG_FILE).
        and_return(Twig::CONFIG_FILE)
    end

    it 'reads and sets a single option' do
      @twig.stub(:branch_names).and_return(['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return(%{
        branch: test
      }.gsub(/^\s+/, ''))
      @twig.options[:branch].should be_nil # Precondition

      @twig.read_config_file

      @twig.options[:branch].should == 'test'
    end

    it 'reads and sets multiple options' do
      @twig.stub(:branch_names).and_return(['test'])
      file = double('file')
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(true)
      File.should_receive(:open).with(Twig::CONFIG_FILE).and_yield(file)
      file.should_receive(:read).and_return(%{
        b:            test
        max-days-old: 30.5
        only-name:    test-only
        except-name:  test-except
      }.gsub(/^\s+/, ''))
      @twig.options[:branch].should be_nil # Precondition
      @twig.options[:max_days_old].should be_nil # Precondition
      @twig.options[:name_only].should be_nil # Precondition
      @twig.options[:name_except].should be_nil # Precondition

      @twig.read_config_file

      @twig.options[:branch].should == 'test'
      @twig.options[:max_days_old].should == 30.5
      @twig.options[:name_only].should == /test-only/
      @twig.options[:name_except].should == /test-except/
    end

    it 'fails gracefully if the config file is not readable' do
      File.should_receive(:readable?).with(Twig::CONFIG_FILE).and_return(false)
      lambda { @twig.read_config_file }.should_not raise_exception
    end
  end

  describe '#set_option' do
    describe 'when setting a :branch option' do
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

    describe 'when setting a :max_days_old option' do
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

    it 'sets a :name_only option' do
      @twig.options[:name_only].should be_nil # Precondition
      @twig.set_option(:name_only, 'important_prefix_')
      @twig.options[:name_only].should == /important_prefix_/
    end

    it 'sets a :name_except option' do
      @twig.options[:name_except].should be_nil # Precondition
      @twig.set_option(:name_except, 'unwanted_prefix_')
      @twig.options[:name_except].should == /unwanted_prefix_/
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
