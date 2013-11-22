require_relative '../test/helper'

describe DBRotator do
  after do
    `mysql -B -e 'SHOW SCHEMAS;'`.split.each do |schema|
      if /^#{TEST_SCHEMA_PREFIX}/.match(schema)
        `mysql -e "DROP SCHEMA #{schema}"`
      end
    end
  end

  def dbname_with(time)
    "__minitest_#{ time.strftime(DBRotator::TIME_FORMAT) }"
  end

  describe "integration" do
    it "works" do
      dbr = DBRotator.new(dummy_config)

      t1 = Time.new(2013, 1, 1)
      t2 = Time.new(2013, 1, 2)
      t3 = Time.new(2013, 1, 3)

      Time.stub(:now, t1) do
        dbr.rotate
        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t1))
        `mysql -B -e 'SHOW TABLES FROM #{dbname_with(t1)};'`.must_include("test")
      end

      Time.stub(:now, t2) do
        dbr.rotate
        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t2))
        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t1))
      end

      Time.stub(:now, t3) do
        dbr.rotate
        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t3))
        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t2))

        `mysql -B -e 'SHOW SCHEMAS;'`.must_include(dbname_with(t1))
      end
    end
  end
end
