
require 'optparse'
require 'pathname'

class DBRotatorConfig
  CONFIG = {
    db_prefix:              [['-p', "--db-prefix PREFIX", "Database naming prefix"], nil],
    scp_command:            [['-c', "--scp-command COMMAND", "Command to retrive dump. Receives second arg of dump path"], nil],

    local_dump_destination: [['-d', "--local-destination [PATH]", "Where to put the dump, as a directory. Won't be deleted after running rotator.", "Default: /tmp"], "/tmp"],
    mysql_command:          [['-m', "--mysql-command [COMMAND]", "Used for all database management operations.", "mysql"], "mysql"],
    maximum_dbs:            [['-n', "--maximum-dbs [N]", "Maximum number of DBs to maintain, or null to disable pruning.", "Default: 2"], 2],
    unarchive_command:      [['-u', "--unarchive-command [COMMAND]", "How to unarchive your dump to standard output.", "Default: bzip2 -cd"], "bzip2 -cd"],
    unarchive_extra_pipe:   [['-i', "--extra-pipes [SCRIPT1,SCRIPT2]", Array, "Any extra script(s) you want to run between unarchive & import.", "Example: -i 'script1,script2'"], nil],
    reasonable_diskspace:   [['-s', "--minimum-diskspace [GB]", "Rough estimate of temporary disk space required to import a typical dump, in GB.", "Default: nil"], nil],
    rails_db_yaml_path:     [['-y', "--rails-db-yaml [PATH]", "Updates database name in your YAML file when given.", "Default: nil"], nil],
    rails_environments:     [['-e', "--rails-db-environments [ENV1,ENV2]", Array, "In conjunction with -y, which rails envs to update DB name for.", "Default [development]"], ["development"]],
  }

  REQUIRED = %i(db_prefix scp_command)
  attr_reader :config

  def initialize
    @config = {}
  end

  def configure
    ARGV.empty? ? from_file : from_cli

    check_required
    add_default_values
    add_derived_values
  end

  def from_cli
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: db-rotator [options]"

      CONFIG.each do |key, pair|
        o = pair.first
        if o[3].nil?
          opts.on(o[0], o[1], o[2]) do |v|
            @config[key] = v
          end
        else
          opts.on(o[0], o[1], o[2], o[3]) do |v|
            @config[key] = v
          end
        end
      end

      opts.on("-v", "--verbose") do |v|
        @config[:verbose] = v
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    parser.parse!(ARGV)
  end

  def check_required
    REQUIRED.each { |k| raise "config option '#{k.to_s} is required'" if @config[k].nil? }
  end

  def add_default_values
    CONFIG.each do |key, pair|
      @config[key] ||= pair.last
    end
  end

  def add_derived_values
    # Figure out the dump filename
    pn = Pathname.new(@config[:scp_command])
    @config[:dump_filename] = pn.basename.to_s
  end
end
