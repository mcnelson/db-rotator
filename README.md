# DBRotator
Easy MySQL database rotation and pruning -- downloads and imports a mysql dump, and then deletes all but N databases, keeping only the newest. This tool is geared toward rotating out achived MySQL backups to your local dev environment. So it works best when you have a most-current MySQL backup as a symlink that updates nightly.

## Installation

`gem install db-rotator`

## Requirements
- This tool creates and drops databases, and runs any SQL in your dump (duh), so you have to give it a user that can do all of that. If you're using this on a local dev environment, it's recommended to setup user/pass in `~/.my.cnf` so that "mysql" works without `-u` or `-p`. You can configure DBRotator to work with any credentials, however. See config section.
- Disk space for N+1 database instances, where N is the amount you want to prune to (maximum DBs).

## Usage

**Minimal usage:**

Run: `db-rotator -p 'appdump_' -c 'scp db5:/opt/backups/latest.sql.bz2'`

**Or, from default config file** `~/.db-rotator.yml`:

```
db_prefix: "appdump_"
scp_command: "scp db5:/opt/backups/latest.sql.bz2"
```

Run: `db-rotator`

**Or, from a specific config file** `/whatever/rotator-config.conf`:

```
db_prefix: "appdump_"
scp_command: "scp db5:/opt/backups/latest.sql.bz2"
```

Run: `db-rotator -f /whatever/rotator-config.conf`

**Rotate nightly**, so you'll always have a fresh dump during your workday:

`0 3 * * * bash -lc "db-rotator -f /whatever/rotator-config.conf >> /some/log/file"`

## Configuration

Run `db-rotator` without any options to show config options.

### Required
#### db_prefix (-p)
Database naming prefix that will apply to all dumps rotated with DBRotator.
Example: `myproject_`, which might name a DB as myproject_09182013.

#### scp_command (-c)
How DBRotator retrieves your dumps. This ideally is an scp command, but really can be any command that receives a second argument of the dump destination.
Example: `scp hostname:/path/to/mysql/backups/backup_filename.sql.bz2`

### Optional

- **local_dump_destination** (-d). Where to put the dump, as a directory. The dump won't be deleted after running rotator. Default: `/tmp`
- **mysql_command** (-m). Used for all database management operations. Default: `mysql`
- **maximum_dbs** (-n). Maximum number of DBs to maintain, or null to disable pruning. Default: 2
- **unarchive_command** (-u). How to unarchive your dump to standard output. Default: `bzip2 -cd`
- **unarchive_extra_pipe** (-i). Any extra script(s) you want to run between unarchive & import. Example: ["/some/filter/for/imported_data", "/some/other/filter/for/imported_data"] Default: nil
- **reasonable_diskspace** (-s). Rough estimate of temporary disk space required to import a typical dump, in GB. Ensures this amount of space is free before importing. Default: nil
- **rails_db_yaml_path** (-y). Updates database name in your YAML file. Example: `/path/to/railsroot/config/database.yml` Default: nil
- **rails_environments** (-e). In conjunction with -y, which rails envs to update DB name for. If passing multiple via command line, use a comma to separate, like `-e "development,staging"`. Default: ["development"]
