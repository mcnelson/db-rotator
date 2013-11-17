
require 'optparse'
require 'pathname'

class DBRotatorConfig
  CONFIG = {
    db_prefix:              ['p', "Database naming prefix"],
    scp_command:            ['c', "Command to retrive dump. Receives second arg of dump path"],

    local_dump_destination: ['d', "Where to put the dump, as a directory. Won't be deleted after running rotator.", "/tmp"],
    mysql_command:          ['m', "Used for all database management operations.", "mysql"],
    maximum_dbs:            ['n', "Maximum number of DBs to maintain, or null to disable pruning.", "2"],
    unarchive_command:      ['u', "How to unarchive your dump to standard output.", "bzip2 -cd"],
    unarchive_extra_pipe:   ['i',  "Any extra script(s) you want to run between unarchive & import.", nil],
    reasonable_diskspace:   ['s', "Rough estimate of temporary disk space required to import a typical dump, in GB.", nil],
    rails_db_yaml_path:     ['y', "Updates database name in your YAML file.", nil],
    rails_environments:     ['e', "In conjunction with -y, which rails envs to update DB name for.", "development"],
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

      CONFIG.each do |key, o|
        value = o[2].nil? ? "VALUE" : "[VALUE]"
        opts.on("-#{o[0]}", "--#{key.to_s.gsub(/_/, '-')} #{value}", o[1]) do |v|
          @config[key] = v
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
    CONFIG.each do |key, o|
      @config[key] ||= o[2]
    end
  end

  def add_derived_values
    # Figure out the dump filename
    pn = Pathname.new(@config[:scp_command])
    @config[:dump_filename] = pn.basename.to_s
  end
end
