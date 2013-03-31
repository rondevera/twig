require 'spec_helper'

describe Twig::GithubRepo do

  before :each do
    @github_https_url          = 'https://github.com/rondevera/twig.git'
                                  # Read-only or read/write
    @github_git_read_only_url  = 'git://github.com/rondevera/twig.git'
    @github_ssh_read_write_url = 'git@github.com:rondevera/twig.git'
  end

  describe '#initialize' do
    it 'runs the given block' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
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
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
      Twig::GithubRepo.any_instance.stub(:username)   { '' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
      Twig::GithubRepo.any_instance.should_receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo name is empty' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { '' }
      Twig::GithubRepo.any_instance.should_receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end
  end

  describe '#origin_url' do
    before :each do
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
    end

    it 'gets the origin URL from the repo config' do
      origin_url = @github_ssh_read_write_url
      Twig::GithubRepo.should_receive(:run).
        with('git config remote.origin.url').once { origin_url }

      Twig::GithubRepo.new do |gh_repo|
        2.times { gh_repo.origin_url }
      end
    end
  end

  describe '#origin_url_parts' do
    before :each do
      Twig::GithubRepo.any_instance.stub(:username)   { 'username' }
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
    end

    it 'splits the origin URL into useful parts' do
      origin_url = @github_ssh_read_write_url
      Twig::GithubRepo.any_instance.stub(:origin_url) { origin_url }

      origin_url_parts = nil
      Twig::GithubRepo.new do |gh_repo|
        origin_url_parts = gh_repo.origin_url_parts
      end

      origin_url_parts.should == %w[
        git@github.com
        rondevera
        twig.git
      ]
    end
  end

  describe '#username' do
    before :each do
      Twig::GithubRepo.any_instance.stub(:repository) { 'repository' }
    end

    it 'gets the username for a HTTPS repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      username.should == 'rondevera'
    end

    it 'gets the username for a Git read-only repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_git_read_only_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      username.should == 'rondevera'
    end

    it 'gets the username for a SSH read/write repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      username.should == 'rondevera'
    end
  end

  describe '#repository' do
    before :each do
      Twig::GithubRepo.any_instance.stub(:username) { 'repository' }
    end

    it 'gets the repo name for a HTTPS repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_https_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      repository.should == 'twig'
    end

    it 'gets the repo name for a Git read-only repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_git_read_only_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      repository.should == 'twig'
    end

    it 'gets the repo name for a SSH read/write repo' do
      Twig::GithubRepo.any_instance.stub(:origin_url) { @github_ssh_read_write_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      repository.should == 'twig'
    end
  end

end
