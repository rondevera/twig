require 'uri'

class Twig
  class GithubRepo
    def initialize
      unless Twig.repo?
        abort 'Current directory is not a git repository.'
      end

      if origin_url.empty? || !github_repo? || username.empty? || repository.empty?
        abort 'This does not appear to be a GitHub repository.'
      end

      yield(self)
    end

    def origin_url
      @origin_url ||= Twig.run('git config remote.origin.url')
    end

    def origin_url_parts
      @origin_url_parts ||= origin_url.split(/[\/:]/)
    end

    def github_repo?
      gh_url_prefix = 'https://github.com'
      uri = URI.parse(gh_url_prefix)
      origin_url.include?(uri.host)
    end

    def username
      @username ||= origin_url_parts[-2] || ''
    end

    def repository
      @repo ||= origin_url_parts[-1].sub(/\.git$/, '') || ''
    end
  end
end
