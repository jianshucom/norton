require 'spec_helper'

describe Norton do
  describe "#setup" do
    it "should setup a redis connection pool" do
      Norton.setup url: 'redis://localhost:6379/0'
      expect(Norton.redis).not_to be_nil
    end
  end

  describe "mget" do
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

      vals = Norton.mget([foobar1, foobar2], [:test_counter, :test_timestamp])

      expect(vals).to include("foobars:#{foobar1.id}:test_counter" => foobar1.test_counter)
      expect(vals).to include("foobars:#{foobar1.id}:test_timestamp" => foobar1.test_timestamp)
      expect(vals).to include("foobars:#{foobar2.id}:test_counter" => foobar2.test_counter)
      expect(vals).to include("foobars:#{foobar2.id}:test_timestamp" => foobar2.test_timestamp)
    end

    it "should get default value correctly if no value in norton redis database" do
      foobar1 = Foobar.new(SecureRandom.hex(2))
      foobar2 = Foobar.new(SecureRandom.hex(2))

      t = Time.now

      Timecop.freeze(t) do
        foobar1.incr_test_counter
        foobar2.touch_test_timestamp
      end

      sleep(1)

      t2 = Time.now

      vals = Timecop.freeze(t2) do
        Norton.mget([foobar1, foobar2], [:test_counter, :test_timestamp])
      end

      expect(vals).to include("foobars:#{foobar1.id}:test_counter" => 1)
      expect(vals).to include("foobars:#{foobar1.id}:test_timestamp" => t2.to_i)
      expect(vals).to include("foobars:#{foobar2.id}:test_counter" => 0)
      expect(vals).to include("foobars:#{foobar2.id}:test_timestamp" => t.to_i)
    end

    it "should return nil for undefined norton values" do
      foobar1 = Foobar.new(SecureRandom.hex(2))
      foobar2 = Foobar.new(SecureRandom.hex(2))

      t = Time.now

      Timecop.freeze(t) do
        foobar1.incr_test_counter
        foobar2.touch_test_timestamp
      end

      vals = Norton.mget([foobar1, foobar2], [:test_counter, :test_timestamp, :test_foobar])

      expect(vals).to include("foobars:#{foobar1.id}:test_counter" => 1)
      expect(vals).to include("foobars:#{foobar2.id}:test_timestamp" => t.to_i)
      expect(vals).to include("foobars:#{foobar1.id}:test_foobar" => nil)
      expect(vals).to include("foobars:#{foobar2.id}:test_foobar" => nil)
    end

    it "returns the default value when the field value is nil" do
      object = Foobar.new(99)
      allow(object).to receive(:test_timestamp_default_value) { 22 }

      ret = Norton.mget([object], %i[test_timestamp])
      expect(ret["foobars:99:test_timestamp"]).to eq(22)
    end

    it "sets the default value in redis if the `Timestamp` field value is nil" do
      object = Foobar.new(99)
      allow(object).to receive(:test_timestamp_default_value) { 22 }

      Norton.mget([object], %i[test_timestamp])

      expect(Norton.redis.with { |conn| conn.get("foobars:99:test_timestamp") }.to_i).to eq(22)
    end
  end
end
