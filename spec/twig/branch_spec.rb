require 'spec_helper'

describe Twig::Branch do
  describe '#initialize' do
    it 'requires a name' do
      branch = Twig::Branch.new('test')
      branch.name.should == 'test'

      lambda { Twig::Branch.new      }.should raise_exception
      lambda { Twig::Branch.new(nil) }.should raise_exception
      lambda { Twig::Branch.new('')  }.should raise_exception
    end

    it 'accepts a `:last_commit_time` attribute' do
      commit_time = Twig::CommitTime.new(Time.now, '99 years ago')
      branch = Twig::Branch.new('test', :last_commit_time => commit_time)
      branch.last_commit_time.should == commit_time

      lambda { Twig::Branch.new('test', :last_commit_time => nil) }.
        should raise_exception
      lambda { Twig::Branch.new('test', :last_commit_time => 'foo') }.
        should raise_exception
    end
  end
end
