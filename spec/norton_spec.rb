require 'spec_helper'

describe Norton do
  describe "#setup" do
    it "should setup a redis connection pool" do
      Norton.setup url: 'redis://localhost:6379/0'
      expect(Norton.redis).not_to be_nil
    end
  end

  describe "norton_vals" do
    class Foobar
      include Norton::Counter
      include Norton::Timestamp

      counter :test_counter
      timestamp :test_timestamp

      def initialize(id)
        @id = id
      end

      def id
        @id
      end
    end

    it "should get the values correctly" do
      foobar1 = Foobar.new(SecureRandom.hex(2))
      foobar2 = Foobar.new(SecureRandom.hex(2))

      Random.rand(100).times { foobar1.incr_test_counter }
      foobar1.touch_test_timestamp

      sleep(2)

      Random.rand(100).times { foobar2.incr_test_counter }
      foobar2.touch_test_timestamp

      vals = Norton.norton_vals([foobar1, foobar2], [:test_counter, :test_timestamp])
    end
  end
end
