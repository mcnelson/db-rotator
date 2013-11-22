# DBRotator
Easy MySQL database rotation and pruning. This downloads and imports a mysql dump, and then deletes all but N databases, keeping only the newest.

## Installation

`gem install db-rotator`

## Requirements
- SSH access to your most current MySQL backup as a single endpoint, like a symlink that updates nightly.
- Root access to destination MySQL instance. If you're using this on a local dev environment, it's recommended to setup username/password in `~/.my.cnf` so that "mysql" works without `-u` or `-p`.
- You have disk space for N+1 database instances, where N is the amount you want to prune to (maximum DBs).

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
### Required
#### **db_prefix (-p)
Database naming prefix that will apply to all dumps rotated with DBRotator.
Example: `myproject_`, which might name a DB as myproject_09182013.

#### scp_command (-c)
How DBRotator retrieves your dumps. This ideally is an scp command, but really can be any command that receives a second argument of the dump destination.
Example: `scp hostname:/path/to/mysql/backups/backup_filename.sql.bz2`

### Optional

- **local_dump_destination** (-d). Where to put the dump, as a directory. Won't be deleted after running rotator. Default: `/tmp`
- **mysql_command** (-m). Used for all database management operations. Default: `mysql`
- **maximum_dbs** (-n). Maximum number of DBs to maintain, or null to disable pruning. Default: 2
- **unarchive_command** (-u). How to unarchive your dump to standard output. Default: `bzip2 -cd`
- **unarchive_extra_pipe** (-i). Any extra script(s) you want to run between unarchive & import. Example: ["/some/filter/for/imported_data", "/some/other/filter/for/imported_data"] Default: nil
- **reasonable_diskspace** (-s). Rough estimate of temporary disk space required to import a typical dump, in GB. Ensures this amount of space is free before importing. Default: nil
- **rails_db_yaml_path** (-y). Updates database name in your YAML file. Example: `/path/to/railsroot/config/database.yml` Default: nil
- **rails_environments** (-e). In conjunction with -y, which rails envs to update DB name for. If passing multiple via command line, use a comma to separate, like `-e "development,staging"`. Default: ["development"]
