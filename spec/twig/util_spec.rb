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

  describe '.truthy?' do
    it 'returns true if an object is truthy' do
      Twig::Util.truthy?('true').should be_true
      Twig::Util.truthy?('TRUE').should be_true
      Twig::Util.truthy?(true).should be_true
      Twig::Util.truthy?('yes').should be_true
      Twig::Util.truthy?('YES').should be_true
      Twig::Util.truthy?('y').should be_true
      Twig::Util.truthy?('Y').should be_true
      Twig::Util.truthy?('on').should be_true
      Twig::Util.truthy?('ON').should be_true
      Twig::Util.truthy?('1').should be_true
      Twig::Util.truthy?(1).should be_true
    end

    it 'returns false if an object is falsy' do
      Twig::Util.truthy?('false').should be_false
      Twig::Util.truthy?(false).should be_false
      Twig::Util.truthy?('yep').should be_false
      Twig::Util.truthy?('sure, why not').should be_false
    end
  end

end
