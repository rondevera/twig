require 'spec_helper'

describe Twig::Branch do
  describe '#initialize' do
    it 'requires a Twig instance' do
      twig = Twig.new
      branch = Twig::Branch.new(twig, 'test')
      branch.twig.should == twig

      lambda { Twig::Branch.new              }.should raise_exception
      lambda { Twig::Branch.new(nil, 'test') }.should raise_exception
      lambda { Twig::Branch.new('', 'test')  }.should raise_exception
    end

    it 'requires a name' do
      twig   = Twig.new
      branch = Twig::Branch.new(twig, 'test')
      branch.name.should == 'test'

      lambda { Twig::Branch.new      }.should raise_exception
      lambda { Twig::Branch.new(nil) }.should raise_exception
      lambda { Twig::Branch.new('')  }.should raise_exception
    end
  end
end
