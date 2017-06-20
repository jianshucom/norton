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

describe Norton::Helper do
  describe "#norton_vals" do
    it "should respond to `:norton_vals`" do
      dummy = Dummy.new

      expect(dummy).to respond_to(:norton_vals)
    end

    it "should return the specific values" do
      dummy = Dummy.new

      dummy.counter1 = 10
      dummy.counter2 = 15
      dummy.counter3 = 100

      dummy.touch_time1

      values = dummy.norton_vals(:counter1, :time1)

      expect(values).to include(:counter1, :time1)
      expect(values.size).to eq(2)
      expect(values[:counter1]).to eq(dummy.counter1)
      expect(values[:time1]).to eq(dummy.time1)
    end

    it "should return nil if the specific key does not exist" do
      dummy = Dummy.new

      dummy.counter1 = 10
      dummy.counter2 = 15
      dummy.counter3 = 100

      dummy.touch_time1

      values = dummy.norton_vals(:counter1, :counter2, :time2)

      expect(values).to include(:counter1, :counter2, :time2)
      expect(values.size).to eq(3)
      expect(values[:counter1]).to eq(dummy.counter1)
      expect(values[:counter2]).to eq(dummy.counter2)
      expect(values[:time2]).to be_nil
    end
  end
end
