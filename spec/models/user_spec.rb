require 'rails_helper'

RSpec.describe User, :type => :model do
  let(:bobby) { FactoryGirl.create(:user) }
  it "has a valid factory" do
    expect(bobby).to be_valid
  end


  context 'when it has a skill' do
    let(:bobby) { FactoryGirl.create(:user_with_skill)}
    it "has a coding skill" do
      expect(bobby.skills.length).to be > 0    
    end
  end

  context 'when it has a game' do
    let(:bobby) { FactoryGirl.create(:user_with_game)}
    it "has a coding skill" do
      expect(bobby.games.length).to be > 0    
    end
  end


  context 'when its username is too long' do
    subject { bobby }
    before { bobby.username = "17 characters++++" }
    it "is not valid" do
      expect(bobby).to_not be_valid
    end
  end

  context 'when its username is nil' do
    subject { bobby }
    before { bobby.username = nil }
    it "is not valid" do
      expect(bobby).to_not be_valid
    end
  end

  context 'when its password is nil' do
    subject { bobby }
    before { bobby.password = nil }
    let(:bobby) { FactoryGirl.build(:user, password: nil) }
    it "is not valid" do
      expect(bobby).to_not be_valid
    end
  end
end