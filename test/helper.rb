require 'minitest/autorun'
require_relative '../lib/db_rotator'
require_relative '../lib/db_rotator_config'

TEST_SCHEMA_PREFIX = "__minitest_"

def dummy_config(config={})
  DBRotatorConfig.new.tap do |cfg|
    cfg.instance_variable_set(:@config, {
      db_prefix:   TEST_SCHEMA_PREFIX,
      scp_command: "cp test/fixtures/basic_dump.sql.bz2",

      local_dump_destination: "/tmp"
    }.merge(config))

    cfg.add_default_values
    cfg.add_derived_values
  end
end
