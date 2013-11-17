# DBRotator
Easy MySQL database rotation and pruning. Tell this utility where your nightly MySQL backup is, and it downloads, imports, and organizes the dump, pruning all but the newest N databases.

## Installation

`gem install db-rotator`

## Usage

1. First off, the following is required:
  - SSH access to your most current MySQL backup as a single endpoint, like a symlink that updates nightly.
  - root access to destination MySQL instance. Recommended to setup username/password in `~/.my.cnf` so that "mysql" works without `-u` or `-p`.

2. Configure the required options (see below). Configuration can be passed as command line arguments or set in `~/.db-rotator.yml`.

  Minimal usage example:

  `db-rotator -p 'appdump_' -c 'scp db5:/opt/backups/latest.sql.bz2'`

  Run `db-rotator -h` for the list of configuration options from CLI.

  You can also set up configuration at `~/.db-rotator.yml`, like so:

      db_prefix: "appdump_"
      scp_command: "scp db5:/opt/backups/latest.sql.bz2"


3. For best results, put that in your crontab, and execute it when you're sure the nightly dump has finished.

  `0 3 * * * db-rotator -p 'appdump_' -c 'scp db5:/opt/backups/latest.sql.bz2' >> /some/log/file`

## Required Configuration
  - **db_prefix** (-p). Database naming prefix. Example: `myproject_`, which might name a DB as myproject_09182013.
  - **scp_command** (-c). Receives second arg of dump path. Example: `scp hostname:/path/to/mysql/backups/backup_filename.sql.bz2`

## Optional Configuration

- **local_dump_destination** (-d). Where to put the dump, as a directory. Won't be deleted after running rotator. Default: `/tmp`
- **mysql_command** (-m). Used for all database management operations. Default: `mysql`
- **maximum_dbs** (-n). Maximum number of DBs to maintain, or null to disable pruning. Default: 2
- **unarchive_command** (-u). How to unarchive your dump to standard output. Default: `bzip2 -cd`
- **unarchive_extra_pipe** (-i). Any extra script(s) you want to run between unarchive & import. Example: ["/some/filter/for/imported_data", "/some/other/filter/for/imported_data"] Default: nil
- **reasonable_diskspace** (-s). Rough estimate of temporary disk space required to import a typical dump, in GB. Ensures this amount of space is free before importing. Default: nil
- **rails_db_yaml_path** (-y). Updates database name in your YAML file. Example: `/path/to/railsroot/config/database.yml` Default: nil
- **rails_environments** (-e). In conjunction with -y, which rails envs to update DB name for. If passing multiple via command line, use a comma to separate, like `-e "development,staging"`. Default: ["development"]
