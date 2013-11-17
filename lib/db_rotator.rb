require 'yaml'

class DBRotator
  TIME_FORMAT = "%Y%m%d"

  def initialize(config)
    @config = config.config
    @schemas = []
    populate_schemas
  end

  def rotate
    refresh
    update_db_yaml
  end

  def refresh
    download_dump
    import
    prune
    grant_access
  end

  def import
    import_dump
    populate_schemas
  end

  private

  def download_dump
    verbose_message "Downloading dump..."
    bash_exec "rm -f #{local_dump_path}"
    bash_exec "#{@config[:scp_command]} #{@config[:local_dump_destination]}/"
  end

  def import_dump
    if reasonable_diskspace?
      verbose_message "Importing dump..."

      mysql_exec "DROP SCHEMA IF EXISTS #{todays_dbname}"
      mysql_exec "CREATE SCHEMA #{todays_dbname}"

      bash_exec %[#{@config[:unarchive_command]} #{local_dump_path} |
                 #{@config[:unarchive_extra_pipe].join(' | ')} |
                 #{@config[:mysql_command]} #{todays_dbname}]
    else
      raise "not enough disk space: #{raw_diskspace}"
    end
  end

  def prune
    verbose_message "Pruning DBs..."

    # keep all but the n newest
    @schemas.sort_by(&:to_date).reverse[@config[:maximum_dbs]..-1].each do |schema|
      mysql_exec "DROP SCHEMA IF EXISTS #{schema.name}"
    end
  end

  def grant_access
    verbose_message "Granting ..."
    mysql_exec "GRANT ALL ON #{todays_dbname}.* to '%'@'localhost'"
  end

  def populate_schemas
    @schemas = raw_schemas.split.each.with_object([]) do |schema_name, memo|
      memo << Schema.new(schema_name) if schema_name =~ schema_regex
    end
  end

  def update_db_yaml
    if @config[:rails_db_yaml_path]
      hash = YAML.load(File.read(@config[:rails_db_yaml_path]))

      @config[:rails_environments].each do |env|
        hash[env.to_s]["database"] = todays_dbname
      end

      File.write(@config[:rails_db_yaml_path], hash.to_yaml)
    end
  end

  def todays_stamp
    Time.now.strftime(TIME_FORMAT)
  end

  def todays_dbname
    "#{@config[:db_prefix]}#{todays_stamp}"
  end

  def schema_regex
    /#{@config[:db_prefix]}([0-9]+)/
  end

  def local_dump_path
    [@config[:local_dump_destination], @config[:dump_filename]].join('/')
  end

  def reasonable_diskspace?
    @config[:reasonable_diskspace] && raw_diskspace.to_i >= @config[:reasonable_diskspace]
  end

  def raw_diskspace
    bash_exec "df -h /dev/mapper/vg_lange-lv_root | awk '{ print $4 }' | tail -n 1"
  end

  def raw_schemas
    bash_exec "#{@config[:mysql_command]} -B -e 'SHOW DATABASES;'"
  end

  def bash_exec(cmd, skip_raise = false)
    out = `#{cmd} || echo '__failed'`
    out = out.strip == "__failed" ? nil : out
    raise "Command failed: #{cmd}" if !skip_raise && !out

    out
  end

  def mysql_exec(cmd)
    bash_exec "#{@config[:mysql_command]} -e '#{cmd}'"
  end

  def verbose_message(msg)
    puts msg if @config[:verbose]
  end

  class Schema
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def to_date
      Date.strptime(
        name.match(schema_regex)[1],
        TIME_FORMAT
      )
    end
  end
end
