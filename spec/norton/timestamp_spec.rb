require 'spec_helper'

class Dummy
  include Norton::Timestamp

  timestamp :born_at
  timestamp :first_kissed_at, :allow_nil => true
  # timestamp :graduated_at, before_save: -> { title_changed? || content_changed? }

  def id
    @id ||= Random.rand(10000)
  end
end

describe Norton::Timestamp do
  describe ".timestamp" do
    it "should add a class method timestamp to the class" do
      expect(Dummy).to respond_to(:timestamp)
    end

    it 'should create timestamp accessors and touch method' do
      dummy = Dummy.new

      expect(dummy).to respond_to(:born_at)
      expect(dummy).to respond_to(:touch_born_at)
    end

    it "should create remove method" do
      dummy = Dummy.new
      expect(dummy).to respond_to(:remove_born_at)
    end
  end

  describe "#touch_born_at" do
    it 'should set timestamp in redis' do
      dummy = Dummy.new
      dummy.touch_born_at

      Norton.redis.with do |conn|
        born_at = conn.get("#{Dummy.to_s.pluralize.downcase}:#{dummy.id}:born_at")
        expect(born_at.to_i).to be > 0
      end
    end
  end

  describe "#born_at" do
    it 'should get the timestamp' do
      dummy = Dummy.new
      dummy.touch_born_at
      expect(dummy.born_at).not_to be_nil
      expect(dummy.born_at).to be_a(Fixnum)
    end

    it "should get current time as a default if timestamp is not touched" do
      dummy = Dummy.new
      t = Time.now

      Timecop.freeze(t) do
        expect(dummy.born_at).to eq(t.to_i)
        expect(dummy.born_at).to eq(t.to_i)
      end
    end
  end

  describe "#first_kissed_at" do
    it "should return nil if not set before because it allows nil" do
      dummy = Dummy.new
      expect(dummy.first_kissed_at).to be_nil
    end
  end
end
