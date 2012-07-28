Dir[File.join(File.dirname(__FILE__), 'twig', '*')].each { |file| require file }

class Twig
  include Display
  include Options

  CONFIG_FILE = '~/.twigrc'
  RESERVED_BRANCH_PROPERTIES = %w[merge remote]
  VERSION = '1.0.0'

  attr_accessor :options


  def initialize(options = {})
    # Options:
    # - :max_days_old (integer)
    # - :name_except (Regexp)
    # - :name_only (Regexp)

    self.options = options
  end

  def current_branch
    @_current_branch ||= `git name-rev --name-only head`.strip
  end

  def branches
    @_branches ||= begin
      refs = `git for-each-ref --format='%(refname)' refs/heads/`.split("\n")
      refs.map! { |ref| ref.sub!('refs/heads/', '') }.sort!

      # Filter branches by name
      refs.select! { |ref| ref =~ options[:name_only]   } if options[:name_only]
      refs.reject! { |ref| ref =~ options[:name_except] } if options[:name_except]

      refs
    end
  end

  def branch_properties
    @_branch_properties ||= begin
      properties = `git config --list`.strip.split("\n").
                      select { |var| var =~ /^branch\./ }.
                      map do |var|
                        match_data = /^branch\.[^.]+\.([^=]+)/.match(var)
                        match_data[1] if match_data
                      end
      properties.uniq.compact.sort - RESERVED_BRANCH_PROPERTIES
    end
  end

  def last_commit_time_for_branch(branch)
    last_commit_times_for_branches[branch]
  end

  def last_commit_times_for_branches
    @_last_commit_times ||= begin
      time_strings = `git show #{branches.join(' ')} --format="%ct,%cr" -s`.
        split("\n").
        reject { |time_string| time_string.empty? }

      commit_times = time_strings.map do |time_string|
        timestamp, time_ago = time_string.split(',')
        timestamp = timestamp.to_i
        Twig::CommitTime.new(timestamp, time_ago)
      end

      Hash[branches.zip(commit_times)]
    end
  end



  ### Actions ###

  def list_branches
    now = Time.now
    max_seconds_old =
      options[:max_days_old] ? options[:max_days_old] * 86400 : nil

    out = "\n" << branch_list_headers

    # Process branches
    branch_lines = []
    branches.each do |branch|
      line = ''
      is_current_branch = (branch == current_branch)

      # Gather branch ages
      last_commit_time = last_commit_time_for_branch(branch)
      seconds_old = now.to_i - last_commit_time.to_i
      next if max_seconds_old && seconds_old > max_seconds_old

      # Gather branch properties
      properties = branch_properties.inject({}) do |hsh, property_name|
        property = get_branch_property(branch, property_name)

        # Use placeholder if empty
        property = column('-') if property.strip.empty?

        hsh.merge(property_name => property)
      end

      # Format branch properties
      line <<
        column(last_commit_time.to_s, 5) <<
        branch_properties.map { |prop| column(properties[prop] || '', 2) }.join
      if is_current_branch
        line << "* #{branch}"
      else
        line << "  #{branch}"
      end

      branch_lines << line
    end

    # List most recently modified branches first
    branch_lines.sort!.reverse!

    # Render current branch as bold; must be done *after* sorting
    current_branch_index =
      branch_lines.index { |line| line =~ /\* #{current_branch}$/ }
    if current_branch_index
      branch_lines[current_branch_index] = format_string(
        branch_lines[current_branch_index], :weight => :bold
      )
    end

    out << branch_lines.join("\n")
  end

  def get_branch_property(branch, key)
    `git config branch.#{branch}.#{key}`.strip
  end

  def set_branch_property(branch, key, value)
    # Sets the given value for the given property key under the current
    # branch. Returns a confirmation string for printing.

    value = value.to_s

    if value.empty?
      `git config --unset branch.#{branch}.#{key}`
      %{Removed #{key} for #{branch}}
    else
      `git config branch.#{branch}.#{key} "#{value}"`
      %{Saved #{key}=#{value} for #{branch}}
    end
  end

end
