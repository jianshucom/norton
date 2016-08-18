require 'spec_helper'

class Dummy
  include Norton::Counter

  counter :candies_count, {} do
    # puts 'hahaha'
    candies
  end

  def id
    @id ||= Random.rand(10000)
  end

  def candies
    15
  end
end

describe Norton::Counter do
  describe "reset counter" do
    it 'should set candies_count' do
      dummy = Dummy.new
      dummy.reset_candies_count

      expect(dummy.candies_count).to eq(15)
    end
  end

  describe "assign value to counter" do
    it 'should be able to assign a value to the counter' do
      dummy = Dummy.new
      dummy.candies_count = 200

      expect(dummy.candies_count).to eq(200)
    end
  end

  describe ".incr_value_by" do
    it "should increase the value of the given amount" do
      dummy = Dummy.new
      dummy.incr_candies_count_by(3)

      expect(dummy.candies_count).to eq(3)
    end
  end

  describe ".decr_value_by" do
    it "should decrease the value of the given amount" do
      dummy = Dummy.new
      dummy.candies_count = 15
      dummy.decr_candies_count_by(5)

      expect(dummy.candies_count).to eq(10)
    end
  end
end
