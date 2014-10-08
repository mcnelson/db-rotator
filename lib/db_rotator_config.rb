
require 'optparse'
require 'pathname'

class DBRotatorConfig
  class FileNotFoundError < StandardError; end

  FILE = ".db-rotator.yml"

  CONFIG = {
    db_prefix:              [['-p', "--db-prefix PREFIX", "Database naming prefix."], nil],
    scp_command:            [['-c', "--scp-command COMMAND", "Command to retrive dump. Receives second arg of dump path."], nil],

    local_dump_destination: [['-d', "--local-destination [PATH]", "Where to put the dump, as a directory. The dump won't be deleted after running rotator.", "Default: /tmp"], "/tmp"],
    mysql_command:          [['-m', "--mysql-command [COMMAND]", "Used for all database management operations.", "Default: mysql"], "mysql"],
    maximum_dbs:            [['-n', "--maximum-dbs [N]", "Maximum number of DBs to maintain, or null to disable pruning.", "Default: 2"], 2],
    unarchive_command:      [['-u', "--unarchive-command [COMMAND]", "How to unarchive your dump to standard output.", "Default: bzip2 -cd"], "bzip2 -cd"],
    unarchive_extra_pipe:   [['-i', "--extra-pipes [SCRIPT1,SCRIPT2]", Array, "Any extra script(s) you want to run between unarchive & import.", "Example: -i 'script1,script2'"], nil],
    reasonable_diskspace:   [['-s', "--minimum-diskspace [GB]", "Rough estimate of temporary disk space required to import a typical dump, in GB."], nil],
    rails_db_yaml_path:     [['-y', "--rails-db-yaml [PATH]", "Updates database name in your YAML file when given.", "Default: nil"], nil],
    rails_environments:     [['-e', "--rails-db-environments [ENV1,ENV2]", Array, "In conjunction with -y, which rails envs to update DB name for. Default: development"], ["development"]],
    on_success:             [['-S', "--on_success [COMMAND]", "Executes command on successful completion."], nil],
    on_failure:             [['-F', "--on_failure [COMMAND]", "Executes command if there is an error."], nil],


    config_file:            [['-f', "--config-file PATH", "Runs rotator with configuration from this .yml file."], nil],
  }

  REQUIRED = %i(db_prefix scp_command)
  EXCLUDE_FROM_GENERATE_FILE = %i(config_file dump_filename)
  attr_reader :config

  def initialize
    @config = {}
    @generate_output_file = nil
  end

  def configure
    begin
      ARGV.empty? ? from_file : from_cli

      if @config[:config_file]
        from_file
      end

      check_required
      add_default_values
      add_derived_values

      if @generate_output_file
        generate_config
        exit
      end

    rescue FileNotFoundError => e
      puts "There was a problem loading configuration: #{e.message}"
      puts cli_parser.summarize
      exit
    end
  end

  def from_cli
    cli_parser.parse!(ARGV)
  end

  def from_file
    raise FileNotFoundError, "no such config file -- #{config_syspath}" unless File.exists?(config_syspath)
    @config = YAML.load_file(config_syspath).each.with_object({}) { |(k, v), h| h[k.to_sym] = v }

    if !(missing = REQUIRED.delete_if { |k| @config[k] }).empty?
      raise "please set config option(s) in #{config_syspath}: #{missing.join(', ')}"
    end
  end

  def cli_parser
    OptionParser.new do |opts|
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

      opts.on("-g", "--generate-config FILE", "Generates .yml config file from given arguments.") do |v|
        @generate_output_file = v
      end

      opts.on("-v", "--verbose") do |v|
        @config[:verbose] = v
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
  end

  def config_syspath
    @config[:config_file] || [ENV['HOME'], FILE].join('/')
  end

  def check_required
    REQUIRED.each { |k| raise "config option '#{k.to_s} is required'" if @config[k].nil? }
  end

  def generate_config
    File.write(@generate_output_file, config_yaml)
  end

  def config_yaml
    @config.reject { |k, _| EXCLUDE_FROM_GENERATE_FILE.include?(k) } .to_yaml
  end

  def add_default_values
    CONFIG.each do |key, pair|
      @config[key] ||= pair.last
    end
  end

  def add_derived_values
    # Figure out the dump filename
    cmd = if @config[:scp_command].strip.match(/^scp/)
            @config[:scp_command].split(':').last
          else
            @config[:scp_command]
          end

    pn = Pathname.new(cmd)
    @config[:dump_filename] = pn.basename.to_s
  end
end
