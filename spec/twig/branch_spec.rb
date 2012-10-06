require 'spec_helper'

describe Twig::Branch do
  before :each do
    @twig = Twig.new
  end

  describe '#initialize' do
    it 'requires a Twig instance' do
      branch = Twig::Branch.new(@twig, 'test')
      branch.twig.should == @twig

      lambda { Twig::Branch.new              }.should raise_exception
      lambda { Twig::Branch.new(nil, 'test') }.should raise_exception
      lambda { Twig::Branch.new('', 'test')  }.should raise_exception
    end

    it 'requires a name' do
      branch = Twig::Branch.new(@twig, 'test')
      branch.name.should == 'test'

      lambda { Twig::Branch.new(@twig)      }.should raise_exception
      lambda { Twig::Branch.new(@twig, nil) }.should raise_exception
      lambda { Twig::Branch.new(@twig, '')  }.should raise_exception
    end
  end

  describe '#to_s' do
    it 'returns the branch name' do
      branch = Twig::Branch.new(@twig, 'test')
      branch.to_s.should == 'test'
    end
  end
end
