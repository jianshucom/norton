require 'spec_helper'

describe Norton do
  describe "#setup" do
    it "should setup a redis connection pool" do
      Norton.setup url: 'redis://localhost:6379/0'
      expect(Norton.redis).not_to be_nil
    end
  end
end
