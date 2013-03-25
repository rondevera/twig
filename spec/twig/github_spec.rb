require 'spec_helper'

describe Twig::GithubRepo do

  describe '#initialize' do
    it 'runs the given block' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { 'origin URL' }
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }

      block_has_run = false
      Twig::GithubRepo.new do |gh_repo|
        block_has_run = true
      end

      block_has_run.should be_true
    end

    it 'aborts if the repo origin URL is empty' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { '' }
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
      Twig::GithubRepo.any_instance.should_receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo username is empty' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { 'origin url' }
      Twig::GithubRepo.any_instance.stub(:username)   { '' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
      Twig::GithubRepo.any_instance.should_receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo name is empty' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { 'origin url' }
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { '' }
      Twig::GithubRepo.any_instance.should_receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end
  end

end
