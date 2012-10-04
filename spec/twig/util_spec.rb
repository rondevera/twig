require 'spec_helper'

describe Twig::Util do
  describe '.numeric?' do
    it 'returns true if an object is numeric' do
      Twig::Util.numeric?(1).should be_true
      Twig::Util.numeric?('1').should be_true
    end

    it 'returns false if an object is not numeric' do
      Twig::Util.numeric?('x').should be_false
      Twig::Util.numeric?([]).should be_false
      Twig::Util.numeric?({}).should be_false
    end
  end
end
