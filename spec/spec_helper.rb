require "simplecov"
require "active_record"
require "nulldb"
require "norton"
require "rspec"
require "timecop"

SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.order = :random

  # Clean Up Redis
  config.before(:each) do
    Norton.pools.each do |_name, conn|
      conn.with { |conn| conn.flushdb }
    end
  end
end

Norton.setup(
  default: { url: "redis://localhost:6379/0" },
  tmp: { url: "redis://localhost:6379/2" }
)

ActiveRecord::Base.establish_connection :adapter => :nulldb
