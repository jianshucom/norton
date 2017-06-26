require 'spec_helper'

class Dummy
  include Norton::Counter
  include Norton::Timestamp

  counter :counter1
  counter :counter2
  counter :counter3

  timestamp :time1

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

    it "should return 0 if the specific key does not exist" do
      dummy = Dummy.new

      dummy.counter1 = 10
      dummy.counter2 = 15
      dummy.counter3 = 100

      dummy.touch_time1

      values = dummy.norton_mget(:counter1, :counter2, :time2)

      expect(values).to include(:counter1, :counter2, :time2)
      expect(values.size).to eq(3)
      expect(values[:counter1]).to eq(dummy.counter1)
      expect(values[:counter2]).to eq(dummy.counter2)
      expect(values[:time2]).to eq(0)
    end
  end
end
