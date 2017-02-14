require 'spec_helper'

describe Norton::Objects::HashMap do
  describe "#hset" do
    it "saves the value of the field in redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")
      expect(Norton.redis.with { |conn| conn.hget(hash_map.key, :name) }).to eq("Bob")
    end
  end

  describe "#hget" do
    it "returns the value of the field from redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")

      expect(hash_map.hget(:name)).to eq("Bob")
    end
  end

  describe "#hdel" do
    it "deletes the field from redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")

      hash_map.hdel(:name)

      expect(hash_map.hget(:name)).to be(nil)
    end

    it "deletes multiple fields from redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")
      hash_map.hset(:age, 21)

      hash_map.hdel(:name, :age)

      expect(hash_map.hget(:name)).to be(nil)
      expect(hash_map.hget(:age)).to be(nil)
    end
  end

  describe "#hincrby" do
    it "increments value by integer at field" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:age, 21)

      hash_map.hincrby(:age, 2)
      expect(hash_map.hget(:age)).to eq("23")
    end

    it "increments value by 1" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:age, 21)

      hash_map.hincrby(:age)
      expect(hash_map.hget(:age)).to eq("22")
    end
  end

  describe "#hdecrby" do
    it "decrements value by integer at field" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:age, 21)

      hash_map.hdecrby(:age, 2)
      expect(hash_map.hget(:age)).to eq("19")
    end
  end

  describe "#hexists" do
    it "returns true if the field exists in redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")

      expect(hash_map.hexists(:name)).to be(true)
    end

    it "returns false if the field doesn't exist in redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")

      expect(hash_map.hexists(:name)).to be(false)
    end
  end

  describe "#hkeys" do
    it "returns all keys in a hash" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")
      hash_map.hset(:age, 21)

      expect(hash_map.hkeys).to match_array(["name", "age"])
    end
  end

  describe "#clear" do
    it "deletes the hash from redis" do
      hash_map = Norton::Objects::HashMap.new("users:99:profile")
      hash_map.hset(:name, "Bob")

      hash_map.clear
      expect(Norton.redis.with { |conn| conn.exists(hash_map.key) }).to eq(false)
    end
  end
end
