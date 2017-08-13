require 'spec_helper'

describe Norton do
  describe "#setup" do
    it "should setup a redis connection pool" do
      Norton.setup url: 'redis://localhost:6379/0'
      expect(Norton.redis).not_to be_nil
    end
  end

  describe ".mget" do
    class Dummy
      include Norton::Counter
      include Norton::Timestamp
      include Norton::HashMap

      counter   :counter1
      timestamp :time1
      hash_map  :map1

      def id
        @id ||= Random.rand(10000)
      end
    end

    let(:dummy) { Dummy.new }

    context "when the field isn't defined" do
      it "doesn't set the instance variable" do
        Norton.mget([dummy], %i[undefined_field])
        expect(dummy.instance_variable_defined?(:@undefined_field)).to be(false)
      end
    end

    context "when the type isn't in the [:counter, :timestamp]" do
      it "doesn't set the instance variable" do
        Norton.mget([dummy], %i[map1])
        expect(dummy.instance_variable_defined?(:@map1)).to be(false)
      end
    end

    context "when the type is in the [:counter, :timestamp]" do
      it "returns norton values correctly from redis" do
        Norton.redis.with do |conn|
          conn.set(dummy.norton_value_key(:counter1), 2)
          conn.set(dummy.norton_value_key(:time1), 1234)
        end

        Norton.mget([dummy], %i[counter1 time1])
        expect(dummy.instance_variable_get(:@counter1)).to eq(2)
        expect(dummy.instance_variable_get(:@time1)).to eq(1234)
      end

      it "returns the default value if no value in redis" do
        allow(dummy).to receive(:counter1_default_value) { 99 }
        allow(dummy).to receive(:time1_default_value) { 1234 }

        Norton.mget([dummy], %i[counter1 time1])
        expect(dummy.instance_variable_get(:@counter1)).to eq(99)
        expect(dummy.instance_variable_get(:@time1)).to eq(1234)
      end
    end

    context "when the type is :counter" do
      it "doesn't save the default value in redis if no value in redis" do
        allow(dummy).to receive(:counter1_default_value) { 99 }

        Norton.mget([dummy], %i[counter1])

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

          expect(
            Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:time2)) }
          ).to eq(false)
        end
      end
    end
  end
end
