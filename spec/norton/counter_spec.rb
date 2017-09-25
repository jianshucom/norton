require "spec_helper"

class Dummy
  include Norton::Counter

  counter :candies_count, {} do
    candies
  end

  counter :views_count, :redis => :tmp do
    14
  end

  def id
    @id ||= Random.rand(10000)
  end

  def candies
    15
  end
end

describe Norton::Counter do
  let(:dummy) { Dummy.new }

  it "responds to methods" do
    expect(dummy.respond_to?(:candies_count)).to be(true)
    expect(dummy.respond_to?(:candies_count=)).to be(true)
    expect(dummy.respond_to?(:candies_count_default_value)).to be(true)
    expect(dummy.respond_to?(:incr_candies_count)).to be(true)
    expect(dummy.respond_to?(:decr_candies_count)).to be(true)
    expect(dummy.respond_to?(:incr_candies_count_by)).to be(true)
    expect(dummy.respond_to?(:decr_candies_count_by)).to be(true)
    expect(dummy.respond_to?(:reset_candies_count)).to be(true)
  end

  describe "#candies_count" do
    it "returns the value correctly" do
      allow(dummy).to receive(:candies_count_default_value) { 123 }

      expect(dummy.candies_count).to eq(123)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(123)
    end
  end

  describe "#candies_count=" do
    it "assigns a value to the counter" do
      dummy.candies_count = "200"

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(200)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(200)
    end
  end

  describe "#candies_count_default_value" do
    it "returns correct default value" do
      expect(dummy.candies_count_default_value).to eq(0)
    end
  end

  describe "#incr_candies_count" do
    it "increases the value by one" do
      dummy.incr_candies_count

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(1)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(1)
    end
  end

  describe "#decr_candies_count" do
    it "decreases the value by one" do
      dummy.candies_count = 15
      dummy.decr_candies_count

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(14)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(14)
    end
  end

  describe "#incr_candies_count_by" do
    it "increases the value of the given amount" do
      dummy.incr_candies_count_by(3)

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(3)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(3)
    end
  end

  describe "#decr_candies_count_by" do
    it "decreases the value of the given amount" do
      dummy.candies_count = 15
      dummy.decr_candies_count_by(5)

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(10)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(10)
    end
  end

  describe "#reset_candies_count" do
    it "resets candies_count" do
      dummy.reset_candies_count

      value_in_redis = Norton.redis.with do |conn|
        conn.get(dummy.norton_value_key(:candies_count))
      end
      expect(value_in_redis.to_i).to eq(15)
      expect(dummy.instance_variable_get(:@candies_count)).to eq(15)
    end
  end

  describe "#remove_candies_count" do
    it "deletes candies_count in redis" do
      dummy.incr_candies_count_by(5)
      expect(
        Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:candies_count)) }
      ).to be(true)

      dummy.remove_candies_count
      expect(
        Norton.redis.with { |conn| conn.exists(dummy.norton_value_key(:candies_count)) }
      ).to be(false)
    end

    it "removes the instance variable named by counter" do
      dummy.incr_candies_count_by(5)
      expect(dummy.instance_variable_defined?(:@candies_count)).to be(true)

      dummy.remove_candies_count
      expect(dummy.instance_variable_defined?(:@candies_count)).to be(false)
    end
  end

  describe "with another redis instance" do
    it "saves the value in correct redis server" do
      dummy.views_count = 10

      value = Norton.pools[:tmp].with { |conn| conn.get(dummy.norton_value_key(:views_count)) }.to_i
      expect(value).to eq(10)
    end

    it "gets the value correctly" do
      Norton.pools[:tmp].with { |conn| conn.set(dummy.norton_value_key(:views_count), 10) }.to_i

      expect(dummy.views_count).to eq(10)
    end
  end
end
