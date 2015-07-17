require 'rails_helper'
RSpec.describe UserHelper, :type => :helper do
  describe '#expand_social_link' do
    let(:username) {"test_user"}
    
    it "should return a full twitter URL when given a username" do
      user = ["link_twitter", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should return a full facebook URL when given a username" do
      user = ["link_facebook", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should return a full google plus URL when given a username" do
      user = ["link_googleplus", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should return a full linkedin URL when given a username" do
      user = ["link_linkedin", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should return a full youtube URL when given a username" do
      user = ["link_youtube", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should return a full instagram URL when given a username" do
      user = ["link_instagram", username]
      expect(helper.expand_social_link(user)).to match(URI::regexp)
    end
    it "should fail gracefully when given an unknown link type" do
      user = ["link_unknown", "unknown"]
      expect(helper.expand_social_link(user)).to eq("unknown")
    end
  end

  describe '#to_b' do
    it 'should convert a string to a variable' do
      expect(helper.to_b("true")).to eq(true)
    end
    it 'should return false when nil is entered' do
      expect(helper.to_b(nil)).to eq(false)
    end
  end
end
