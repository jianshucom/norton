require 'spec_helper'

class Dummy
  include Norton::Counter

  counter :candies_count, {} do
    # puts 'hahaha'
    candies
  end

  def id
    Random.rand(10000)
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

      dummy.candies_count.must_equal 15
    end
  end

  describe "assign value to counter" do
    it 'should be able to assign a value to the counter' do
      dummy = Dummy.new
      dummy.candies_count = 200

      dummy.candies_count.must_equal 200
    end
  end
end