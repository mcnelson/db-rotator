require_relative '../test/helper'

describe DBRotator do
  describe "integration" do
    it "works" do
      dbr = DBRotator.new(dummy_config)
      dbr.rotate
    end
  end
end
