require 'spec_helper'

class Dummy
  include Norton::Counter
  include Norton::Timestamp
  include Norton::HashMap

  counter   :counter1
  timestamp :time1
  timestamp :time2, :allow_nil => true
  hash_map  :map1

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
  describe ".register_norton_value" do
    it "should raise error if type is not supported" do
      expect {
        Dummy.register_norton_value("foo", "bar")
      }.to raise_error(Norton::InvalidType)
    end

    it "adds the fields with valid type to `@norton_values`" do
      Dummy.register_norton_value("foo", "counter")
      expect(Dummy.norton_values[:foo][:type]).to eq(:counter)
    end

    it "adds the fields with options" do
      Dummy.register_norton_value("foo", "counter", :allow_nil => true)
      expect(Dummy.norton_values[:foo][:type]).to eq(:counter)
      expect(Dummy.norton_values[:foo][:allow_nil]).to eq(true)
    end
  end

  describe ".norton_value_defined?" do
    it "should return true for a defined value" do
      expect(Dummy.norton_value_defined?(:counter1)).to eq(true)
    end

    it "should return false for a undefined value" do
      expect(Dummy.norton_value_defined?(:time3)).to eq(false)
    end
  end

  describe ".norton_value_type" do
    it "returns the type for a defined value" do
      Dummy.register_norton_value("foo", "counter")
      expect(Dummy.norton_value_type("foo")).to eq(:counter)
    end
  end

  describe "#norton_prefix" do
    let(:dummy) { Dummy.new }
    let(:spammer) { HolyLight::Spammer.new }

    it "raises error if the object's id is nil" do
      allow(dummy).to receive(:id) { nil }
      expect { dummy.norton_prefix }.to raise_error(Norton::NilObjectId)
    end

    it "returns correctly for valid objects" do
      expect(dummy.norton_prefix).to eq("dummies:#{dummy.id}")
      expect(spammer.norton_prefix).to eq("holy_light/spammers:#{spammer.id}")
    end

    it "should return correctly for `HolyLight::Spammer`" do
      spammer = HolyLight::Spammer.new
      expect(spammer.norton_prefix).to eq("holy_light/spammers:#{spammer.id}")
    end
  end

  describe "#norton_value_key" do
    let(:dummy) { Dummy.new }

    it "returns the redis key correctly" do
      allow(dummy).to receive(:norton_prefix) { "foobar" }

      expect(dummy.norton_value_key("lol")).to eq("foobar:lol")
    end
  end

  describe "#norton_mget" do
    let(:dummy) { Dummy.new }

    context "when the field isn't defined" do
      it "doesn't set the instance variable" do
        dummy.norton_mget(:undefined_field)
        expect(dummy.instance_variable_defined?(:@undefined_field)).to be(false)
      end
    end

    context "when the type isn't in the [:counter, :timestamp]" do
      it "doesn't set the instance variable" do
        dummy.norton_mget(:map1)
        expect(dummy.instance_variable_defined?(:@map1)).to be(false)
      end
    end

    context "when the type is in the [:counter, :timestamp]" do
      it "returns norton values correctly from redis" do
        Norton.redis.with do |conn|
          conn.set(dummy.norton_value_key(:counter1), 2)
          conn.set(dummy.norton_value_key(:time1), 1234)
        end

        dummy.norton_mget(:counter1, :time1)
        expect(dummy.instance_variable_get(:@counter1)).to eq(2)
        expect(dummy.instance_variable_get(:@time1)).to eq(1234)
      end

      it "returns the default value if no value in redis" do
        allow(dummy).to receive(:counter1_default_value) { 99 }
        allow(dummy).to receive(:time1_default_value) { 1234 }

        dummy.norton_mget(:counter1, :time1)
        expect(dummy.instance_variable_get(:@counter1)).to eq(99)
        expect(dummy.instance_variable_get(:@time1)).to eq(1234)
      end
    end

    context "when the type is :counter" do
      it "doesn't save the default value in redis if no value in redis" do
        allow(dummy).to receive(:counter1_default_value) { 99 }

        dummy.norton_mget(:counter1)

        value_from_redis = Norton.redis.with do |conn|
          conn.get(dummy.norton_value_key(:counter1))
        end
        expect(value_from_redis).to be(nil)
      end
    end

    context "when the type is :timestamp" do
      context "when the attribute doesn't allow nil" do
        it "saves the default value in redis if no value in redis" do
          allow(dummy).to receive(:time1_default_value) { 1234 }

          dummy.norton_mget(:time1)

          value_from_redis = Norton.redis.with do |conn|
            conn.get(dummy.norton_value_key(:time1))
          end.to_i
          expect(value_from_redis).to eq(1234)
        end
      end

      context "when the attribute allow nil" do
        it "doesn't save the default value in redis if no value in redis" do
          allow(dummy).to receive(:time2_default_value) { nil }

          dummy.norton_mget(:time2)

          expect(dummy.time2).to be_nil
          expect(
            Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:time2)) }
          ).to eq(false)
        end
      end
    end
  end
end
