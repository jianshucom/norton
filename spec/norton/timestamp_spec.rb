require 'spec_helper'

class Dummy
  include Norton::Timestamp

  timestamp :born_at
  timestamp :thirteen_ts, :digits => 13
  timestamp :first_kissed_at, :allow_nil => true

  def id
    @id ||= Random.rand(10000)
  end
end

describe Norton::Timestamp do
  let(:dummy) { Dummy.new }

  it "responds to methods" do
    expect(dummy.respond_to?(:born_at)).to be(true)
    expect(dummy.respond_to?(:born_at_default_value)).to be(true)
    expect(dummy.respond_to?(:touch_born_at)).to be(true)
    expect(dummy.respond_to?(:remove_born_at)).to be(true)

    expect(Dummy.norton_values[:thirteen_ts][:type]).to eq(:timestamp)
    expect(Dummy.norton_values[:thirteen_ts][:digits]).to eq(13)
    expect(Dummy.norton_values[:first_kissed_at][:allow_nil]).to eq(true)
    expect(Dummy.norton_values[:first_kissed_at][:allow_nil]).to eq(true)
  end

  describe "#born_at" do
    it "returns the timestamp correctly" do
      Norton.redis.with do |conn|
        conn.set(dummy.norton_value_key(:born_at), 123)
      end

      expect(dummy.born_at).to eq(123)
      expect(dummy.instance_variable_get(:@born_at)).to eq(123)
    end

    it "returns default timestamp if no value in norton" do
      allow(dummy).to receive(:born_at_default_value) { 456 }
      dummy.born_at

      value = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:born_at))
      end
      expect(value.to_i).to eq(456)
    end

    it "returns nil if no value in norton and the timestamp allows nil" do
      expect(dummy.first_kissed_at).to be_nil
    end
  end

  describe "#born_at_default_value" do
    it "returns nil if the timestamp allow nil" do
      expect(dummy.first_kissed_at_default_value).to eq(nil)
    end

    it "returns the current time as timestamp" do
      Timecop.freeze(Time.current) do
        expect(dummy.born_at_default_value).to eq(Time.current.to_i)
      end
    end

    it "returns the current time as 13 digit timestamp" do
      Timecop.freeze(Time.current) do
        expect(dummy.thirteen_ts_default_value).to eq((Time.current.to_f * 1000).to_i)
      end
    end
  end

  describe "#touch_born_at" do
    it "sets the timestamp to the current time" do
      Timecop.freeze(Time.current) do
        dummy.touch_born_at

        expect(
          Norton.redis.with { |conn| conn.get(dummy.norton_value_key(:born_at)) }.to_i
        ).to eq(Time.current.to_i)
      end
    end

    it "sets the timestamp to the current time as 13 digit timestamp" do
      Timecop.freeze(Time.current) do
        dummy.touch_thirteen_ts

        expect(
          Norton.redis.with { |conn| conn.get(dummy.norton_value_key(:thirteen_ts)) }.to_i
        ).to eq((Time.current.to_f * 1000).to_i)
      end
    end

    it "sets the instance variable named by timestamp" do
      Timecop.freeze(Time.current) do
        dummy.touch_born_at
        expect(dummy.instance_variable_get(:@born_at)).to eq(Time.current.to_i)
      end
    end
  end

  describe "#remove_born_at" do
    it "deletes the timestamp in the redis" do
      dummy.touch_born_at
      expect(
        Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:born_at)) }
      ).to be(true)

      dummy.remove_born_at
      expect(
        Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:born_at)) }
      ).to be(false)
    end

    it "removes the instance variable named by timestamp" do
      dummy.touch_born_at
      expect(dummy.instance_variable_defined?(:@born_at)).to be(true)

      dummy.remove_born_at
      expect(dummy.instance_variable_defined?(:@born_at)).to be(false)
    end
  end
end
