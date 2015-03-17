require 'spec_helper'

class Dummy
  include Norton::Timestamp

  timestamp :born_at
  # timestamp :graduated_at, before_save: -> { title_changed? || content_changed? }

  def id
    1
  end
end

describe Norton::Timestamp do
  describe "#timestamp" do
    it "should add a class method timestamp to the class" do
      Dummy.must_respond_to :timestamp
    end

    it 'should create timestamp accessors and touch method' do
      dummy = Dummy.new

      dummy.must_respond_to :born_at
      # dummy.must_respond_to :'born_at='
      dummy.must_respond_to :touch_born_at
    end
  end

  describe ".touch_born_at" do
    it 'should set timestamp in redis' do
      dummy = Dummy.new
      dummy.touch_born_at

      Norton.redis.with do |conn|
        born_at = conn.get("#{Dummy.to_s.pluralize.downcase}:#{dummy.id}:born_at")
        born_at.to_i.must_be :>, 0
      end
    end
  end

  describe ".born_at" do
    it 'should get the timestamp' do
      dummy = Dummy.new
      dummy.touch_born_at
      dummy.born_at.wont_be_nil
      dummy.born_at.must_be_kind_of Fixnum
    end
  end
end