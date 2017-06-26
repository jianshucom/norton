require 'spec_helper'

class HashMapObject
  include Norton::HashMap

  hash_map :profile

  def id
    @id ||= 99
  end
end

describe Norton::HashMap do
  describe "#norton_value_key" do
    it "generates the correct field key" do
      object = HashMapObject.new
      expect(object.norton_value_key(:profile)).to eq("hash_map_objects:99:profile")
    end
  end

  describe "#hash_map" do
    it "sets a instance variable" do
      object = HashMapObject.new
      expect(object.profile).to be_a(Norton::Objects::Hash)
    end
  end
end
