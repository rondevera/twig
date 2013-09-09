require 'spec_helper'

describe Twig::Util do
  describe '.numeric?' do
    it 'returns true if an object is numeric' do
      expect(Twig::Util.numeric?(1)).to be_true
      expect(Twig::Util.numeric?('1')).to be_true
    end

    it 'returns false if an object is not numeric' do
      expect(Twig::Util.numeric?('x')).to be_false
      expect(Twig::Util.numeric?([])).to be_false
      expect(Twig::Util.numeric?({})).to be_false
    end
  end

  describe '.truthy?' do
    it 'returns true if an object is truthy' do
      expect(Twig::Util.truthy?('true')).to be_true
      expect(Twig::Util.truthy?('TRUE')).to be_true
      expect(Twig::Util.truthy?(true)).to be_true
      expect(Twig::Util.truthy?('yes')).to be_true
      expect(Twig::Util.truthy?('YES')).to be_true
      expect(Twig::Util.truthy?('y')).to be_true
      expect(Twig::Util.truthy?('Y')).to be_true
      expect(Twig::Util.truthy?('on')).to be_true
      expect(Twig::Util.truthy?('ON')).to be_true
      expect(Twig::Util.truthy?('1')).to be_true
      expect(Twig::Util.truthy?(1)).to be_true
    end

    it 'returns false if an object is falsy' do
      expect(Twig::Util.truthy?('false')).to be_false
      expect(Twig::Util.truthy?(false)).to be_false
      expect(Twig::Util.truthy?('yep')).to be_false
      expect(Twig::Util.truthy?('sure, why not')).to be_false
    end
  end

end
