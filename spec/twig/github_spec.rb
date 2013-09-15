require 'spec_helper'

describe Twig::GithubRepo do

  before :each do
    @github_https_url           = 'https://github.com/rondevera/twig.git'
                                  # Read-only or read/write
    @github_git_read_only_url   = 'git://github.com/rondevera/twig.git'
    @github_ssh_read_write_url  = 'git@github.com:rondevera/twig.git'

    @generic_https_url          = 'https://example.com/rondevera/twig.git'
    @generic_git_read_only_url  = 'git://example.com/rondevera/twig.git'
    @generic_ssh_read_write_url = 'git@example.com:rondevera/twig.git'
  end

  describe '#initialize' do
    it 'runs the given block' do
      origin_url = @github_ssh_read_write_url
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }

      block_has_run = false
      Twig::GithubRepo.new do |gh_repo|
        block_has_run = true
      end

      expect(block_has_run).to be_true
    end

    it 'aborts if this is not a Git repo' do
      origin_url = @github_ssh_read_write_url
      allow(Twig).to receive(:repo?) { false }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
      expect_any_instance_of(Twig::GithubRepo).to receive(:abort) do |message|
        expect(message).to include('not a git repository')
      end

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo origin URL is empty' do
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { '' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
      expect_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo username is empty' do
      origin_url = @github_ssh_read_write_url
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { '' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
      expect_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo name is empty' do
      origin_url = @github_ssh_read_write_url
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { '' }
      expect_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end

    it 'aborts if the repo is not hosted by GitHub' do
      origin_url = @generic_ssh_read_write_url
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
      expect_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)

      Twig::GithubRepo.new { |gh_repo| } # Do nothing
    end
  end

  describe '#origin_url' do
    before :each do
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
    end

    it 'gets the origin URL from the repo config' do
      origin_url = @github_ssh_read_write_url
      expect(Twig).to receive(:run).
        with('git config remote.origin.url').once { origin_url }

      Twig::GithubRepo.new do |gh_repo|
        2.times { gh_repo.origin_url }
      end
    end
  end

  describe '#origin_url_parts' do
    before :each do
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username)   { 'username' }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
    end

    it 'splits the origin URL into useful parts' do
      origin_url = @github_ssh_read_write_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }

      origin_url_parts = nil
      Twig::GithubRepo.new do |gh_repo|
        origin_url_parts = gh_repo.origin_url_parts
      end

      expect(origin_url_parts).to eq(%w[
        git@github.com
        rondevera
        twig.git
      ])
    end
  end

  describe '#github_repo?' do
    before :each do
      allow(Twig).to receive(:repo?) { true }
    end

    context 'with a GitHub HTTPS URL' do
      before :each do
        origin_url = @github_https_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      end

      it 'returns true' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_true
      end
    end

    context 'with a GitHub Git read-only URL' do
      before :each do
        origin_url = @github_git_read_only_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      end

      it 'returns true' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_true
      end
    end

    context 'with a GitHub SSH read/write URL' do
      before :each do
        origin_url = @github_ssh_read_write_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      end

      it 'returns true' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_true
      end
    end

    context 'with a generic HTTPS URL' do
      before :each do
        origin_url = @generic_https_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
        allow_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)
      end

      it 'returns false' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_false
      end
    end

    context 'with a generic Git read-only URL' do
      before :each do
        origin_url = @generic_git_read_only_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
        allow_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)
      end

      it 'returns false' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_false
      end
    end

    context 'with a generic SSH read/write URL' do
      before :each do
        origin_url = @generic_ssh_read_write_url
        allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
        allow_any_instance_of(Twig::GithubRepo).to receive(:abort_for_non_github_repo)
      end

      it 'returns false' do
        is_github_repo = nil
        Twig::GithubRepo.new do |gh_repo|
          is_github_repo = gh_repo.github_repo?
        end

        expect(is_github_repo).to be_false
      end
    end
  end

  describe '#username' do
    before :each do
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:repository) { 'repository' }
    end

    it 'gets the username for a HTTPS repo' do
      origin_url = @github_ssh_read_write_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      expect(username).to eq('rondevera')
    end

    it 'gets the username for a Git read-only repo' do
      origin_url = @github_git_read_only_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      expect(username).to eq('rondevera')
    end

    it 'gets the username for a SSH read/write repo' do
      origin_url = @github_ssh_read_write_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      username = nil
      Twig::GithubRepo.new do |gh_repo|
        username = gh_repo.username
      end

      expect(username).to eq('rondevera')
    end
  end

  describe '#repository' do
    before :each do
      allow(Twig).to receive(:repo?) { true }
      allow_any_instance_of(Twig::GithubRepo).to receive(:username) { 'repository' }
    end

    it 'gets the repo name for a HTTPS repo' do
      origin_url = @github_https_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      expect(repository).to eq('twig')
    end

    it 'gets the repo name for a Git read-only repo' do
      origin_url = @github_git_read_only_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      expect(repository).to eq('twig')
    end

    it 'gets the repo name for a SSH read/write repo' do
      origin_url = @github_ssh_read_write_url
      allow_any_instance_of(Twig::GithubRepo).to receive(:origin_url) { origin_url }
      repository = nil
      Twig::GithubRepo.new do |gh_repo|
        repository = gh_repo.repository
      end

      expect(repository).to eq('twig')
    end
  end

end
