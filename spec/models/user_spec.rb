require 'rails_helper'

RSpec.describe User, :type => :model do
  let(:bobby) { FactoryGirl.create(:user) }
  it "has a valid factory" do
    expect(bobby).to be_valid
  end

  it 'should fail when trying to change password with an invalid old password' do # Wow that was long
    bobby.old_password = "invalid password"
    newpass = "new password"
    bobby.password, bobby.password_confirmation = newpass, newpass
    expect(bobby).to_not be_valid
  end

  context 'when it has a special email' do
    let(:email) { "test@email.com" }
    let(:bobby) { FactoryGirl.create(:user, email: email) }

    it "has an encrypted email" do
      expect(bobby.email).to_not be email
    end

    it "has a valid decrypted email" do
      expect(bobby.decrypted_email).to eq(email)
    end
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