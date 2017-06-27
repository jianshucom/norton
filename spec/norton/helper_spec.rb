require 'spec_helper'

class Dummy
  include Norton::Counter
  include Norton::Timestamp
  include Norton::HashMap

  counter :counter1
  counter :counter2
  counter :counter3

  timestamp :time1
  timestamp :time2

  hash_map :map1

  def id
    @id ||= Random.rand(10000)
  end
end

module HolyLight
  class Spammer
    include Norton::Counter

    def id
      @id ||= Random.rand(10000)
    end
  end
end

describe Norton::Helper do
  describe "@norton_values" do
    it "should contain defined values and type" do
      expect(Dummy.norton_values[:counter1]).to eq(:counter)
      expect(Dummy.norton_values[:counter2]).to eq(:counter)
      expect(Dummy.norton_values[:counter3]).to eq(:counter)

      expect(Dummy.norton_values[:time1]).to eq(:timestamp)
      expect(Dummy.norton_values[:time2]).to eq(:timestamp)

      expect(Dummy.norton_values[:map1]).to eq(:hash_map)
    end

    it "should not contain undefined values" do
      expect(Dummy.norton_values[:foobar]).to be_nil
    end
  end

  describe ".register_norton_value" do
    it "should raise error if type is not supported" do
      expect {
        Dummy.register_norton_value("foo", "bar")
      }.to raise_error(Norton::InvalidType)
    end
  end

  describe ".norton_value_defined?" do
    it "should return true for a defined value" do
      expect(Dummy.norton_value_defined?(:counter1)).to eq(true)
    end

    it "should return false for a defined value" do
      expect(Dummy.norton_value_defined?(:time3)).to eq(false)
    end
  end

  describe "#norton_value_key" do
    it do
      n = SecureRandom.hex(3)

      dummy = Dummy.new
      expect(dummy.norton_value_key(n)).to eq("dummies:#{dummy.id}:#{n}")
    end

    it "should raise `Norton::NilObjectId` if id returns nil" do
      dummy = Dummy.new
      allow(dummy).to receive(:id) { nil }

      expect { dummy.norton_prefix }.to raise_error(Norton::NilObjectId)
    end
  end

  describe "#norton_prefix" do
    it "should return correctly for `Dummy`" do
      dummy = Dummy.new
      expect(dummy.norton_prefix).to eq("dummies:#{dummy.id}")
    end

    it "should return correctly for `HolyLight::Spammer`" do
      spammer = HolyLight::Spammer.new
      expect(spammer.norton_prefix).to eq("holy_light/spammers:#{spammer.id}")
    end
  end

  describe "#norton_mget" do
    it "should respond to `:norton_mget`" do
      dummy = Dummy.new

      expect(dummy).to respond_to(:norton_mget)
    end

    it "should return the specific values" do
      dummy = Dummy.new

      dummy.counter1 = 10
      dummy.counter2 = 15
      dummy.counter3 = 100

      dummy.touch_time1

      values = dummy.norton_mget(:counter1, :time1)

      expect(values).to include(:counter1, :time1)
      expect(values.size).to eq(2)
      expect(values[:counter1]).to eq(dummy.counter1)
      expect(values[:time1]).to eq(dummy.time1)
    end

    it "should default value if the value of does not exist" do
      dummy = Dummy.new

      dummy.counter1 = 10
      dummy.counter2 = 15

      dummy.touch_time1

      t = Time.now

      Timecop.freeze(t) do
        values = dummy.norton_mget(:counter1, :counter2, :time2)

        expect(values).to include(:counter1, :counter2, :time2)
        expect(values.size).to eq(3)
        expect(values[:counter1]).to eq(dummy.counter1)
        expect(values[:counter2]).to eq(dummy.counter2)
        expect(values[:time2]).to eq(t.to_i)
      end
    end

    it "should save the default value for timestamp" do
      dummy = Dummy.new

      t = Time.now

      Timecop.freeze(t) do
        values = dummy.norton_mget(:time2)
        expect(values[:time2]).to eq(t.to_i)

        # Test value directly from Redis
        val = Norton.redis.with { |conn| conn.get(dummy.norton_value_key(:time2)) }.to_i
        expect(val).to eq(t.to_i)
      end
    end

    it "should not save the default value for counter" do
      dummy = Dummy.new

      t = Time.now

      Timecop.freeze(t) do
        values = dummy.norton_mget(:counter1)
        expect(values[:counter1]).to eq(0)

        # Test value directly from Redis
        expect(Norton.redis.with { |conn| conn.get(dummy.norton_value_key(:counter1)) }).to be_nil
      end
    end

    it "should return nil if the norton value is not defined" do
      dummy = Dummy.new

      values = dummy.norton_mget(:time3)

      expect(values).to include(:time3)
      expect(values[:time3]).to be_nil
    end
  end
end
