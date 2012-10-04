require 'spec_helper'

describe Twig::Options do
  before :each do
    @twig = Twig.new
  end

  describe '#set_option' do
    describe 'when setting a :branch option' do
      before :each do
        @twig.options[:branch].should be_nil # Precondition
      end

      it 'succeeds' do
        @twig.should_receive(:branches).and_return(%[foo bar])
        @twig.set_option(:branch, 'foo')
        @twig.options[:branch].should == 'foo'
      end

      it 'fails if the branch is unknown' do
        @twig.should_receive(:branches).and_return([])
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
