
require 'optparse'

class DBRotatorConfig
  CONFIG = {
    db_prefix:              ['p', "Database naming prefix"],
    scp_command:            ['c', "Command to retrive dump. Receives second arg of dump path"],

    local_dump_destination: ['d', "Where to put the dump, as a directory. Won't be deleted after running rotator.", "/tmp"],
    mysql_command:          ['m', "Used for all database management operations.", "mysql"],
    maximum_dbs:            ['n', "Maximum number of DBs to maintain, or null to disable pruning.", "2"],
    unarchive_command:      ['u', "How to unarchive your dump to standard output.", "bzip2 -cd"],
    unarchive_extra_pipe:   ['i',  "Any extra script(s) you want to run between unarchive & import.", "nil"],
    reasonable_diskspace:   ['s', "Rough estimate of temporary disk space required to import a typical dump, in GB.", "nil"],
    rails_db_yaml_path:     ['y', "Updates database name in your YAML file.", "nil"],
    rails_environments:     ['e', "In conjunction with -y, which rails envs to update DB name for.", "development"],
  }

  REQUIRED = %i(db_prefix scp_command)

  def initialize
    @config = {}
  end

  def cli_parse(args)
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: db-rotator [options]"

      CONFIG.each do |key, o|
        default = o[2] ? "Default: #{o[2]}" : nil
        opts.on("-#{o[0]}", "--#{key.to_s.gsub(/_/, '-')}", o[1], default) do |v|
          @config = v
        end
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end

    parser.parse!(args)
  end
end
