require 'spec_helper'

describe Norton do
  describe "#setup" do
    it "should setup a redis connection pool" do
      Norton.setup url: 'redis://localhost:6379/0'

      Norton.redis.wont_be_nil
    end
  end
end