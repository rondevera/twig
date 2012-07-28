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
    out = "\n"
    now = Time.now

    # Prepare column headers
    header_options = {:color => :blue}
    out << column(' ', 5) <<
      branch_properties.map { |prop|
        column(prop, 2, header_options)
      }.join <<
      column('  branch', 1, header_options) << "\n"
    out << column(' ', 5) <<
      branch_properties.map { |prop|
        column('-' * prop.size, 2, header_options)
      }.join <<
      column('  ------', 1, header_options) << "\n"

    # Process branches
    branch_lines = []
    branches.each do |branch|
      line = ''
      is_current_branch = (branch == current_branch)

      # Gather branch ages
      last_commit_time = last_commit_time_for_branch(branch)
      if options[:max_days_old]
        max_seconds_old = options[:max_days_old] * 86400
        next if last_commit_time.to_i < now.to_i - max_seconds_old
      end

      # Gather branch properties
      properties = branch_properties.inject({}) do |hsh, property_name|
        property = get_branch_property(branch, property_name)
        hsh.merge(property_name => property)
      end

      # Add placeholders for empty branch properties
      properties.each do |key, value|
        properties[key] = column('-') if value.strip.empty?
      end

      # Format branch properties
      line << column(last_commit_time.to_s, 5) <<
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

    # Render current branch as bold
    current_branch_index =
      branch_lines.index { |line| line =~ /\* #{current_branch}$/ }
    if current_branch_index
      line = branch_lines[current_branch_index]
      branch_lines[current_branch_index] = "\033[1m#{line}\033[0m"
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
