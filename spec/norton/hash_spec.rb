require 'spec_helper'

class HashObject
  include Norton::Hash

  hash_map :profile

  def id
    @id ||= 99
  end
end

describe Norton::Hash do
  describe "#norton_field_key" do
    it "generates the correct field key" do
      object = HashObject.new
      expect(object.norton_field_key(:profile)).to eq("hash_objects:99:profile")
    end

    it "raises NilObjectId if the object id is nil" do
      object = HashObject.new
      allow(object).to receive(:id) { nil }

      expect { object.norton_field_key(:profile) }.to raise_error(Norton::NilObjectId)
    end
  end

  describe "#hash_map" do
    it "sets a instance variable" do
      object = HashObject.new
      expect(object.profile).to be_a(Norton::Objects::HashMap)
    end
  end
end
