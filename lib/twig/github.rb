class Twig
  class GithubRepo
    def initialize
      if origin_url.empty? || username.empty? || repository.empty?
        abort_for_non_github_repo
      end

      yield(self)
    end

    def origin_url
      @origin_url ||= `git config remote.origin.url`.strip
    end

    def origin_url_parts
      @origin_url_parts ||= origin_url.split(/[\/:]/)
    end

    def username
      @username ||= origin_url_parts[-2] || ''
    end

    def repository
      @repo ||= origin_url_parts[-1].sub(/\.git$/, '') || ''
    end

    def abort_for_non_github_repo
      abort 'This does not appear to be a GitHub repository.'
    end
  end
end
