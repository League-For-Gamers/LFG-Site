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

  context 'when entering an email' do
    let(:email) { "test@email.com" }
    let(:bobby) { FactoryGirl.create(:user, email: email, email_confirm: email) }
    it 'is encrypted' do
      expect(bobby.email).to_not be email
    end
    it 'is hashed' do
      expect(bobby.hashed_email).to_not eq(email)
    end
    it 'has a valid decrypted email' do
      expect(bobby.decrypted_email).to eq(email)
    end
    it 'cannot have a duplicate' do
      new_user = FactoryGirl.build(:user, username: "NotBobby", display_name: "Not Bobby", email: bobby.decrypted_email, email_confirm: email)
      expect(new_user).to_not be_valid
    end
  end

  context 'when entering zalgo in a displayed field' do
    it 'is removed from display_name' do
      bobby.display_name = "Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝"
      bobby.valid? # Run it thought the validators
      expect(bobby.display_name).to eq("ZalgoString")
      expect(bobby.display_name).to_not eq("Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝")
    end

    it 'is removed from bio' do
      bobby.bio = "Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝"
      bobby.valid? # Run it thought the validators
      expect(bobby.bio).to eq("ZalgoString")
      expect(bobby.bio).to_not eq("Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝")
    end
  end

  describe '#has_permission?' do
    let(:bobby) { FactoryGirl.create(:administrator_user) }

    it 'should return true for a user that has the permission' do
      permission = bobby.role.permissions.first
      expect(bobby.has_permission?(permission.name)).to be(true)
    end

    it 'should return false for when the user does not have a permission' do
      expect(bobby.has_permission?("fake_permission")).to be(false)
    end
  end

  describe '#generate_verification_digest' do
    it 'should generate a new verification digest' do
      bobby.generate_verification_digest
      expect(bobby.verification_digest).to be_present
      expect(bobby.verification_active).to be_present
    end

    it 'should not generate a new digest over an active one' do
      bobby.generate_verification_digest
      old_digest = bobby.verification_digest
      bobby.generate_verification_digest
      expect(bobby.verification_digest).to eq(old_digest)
    end
  end

  describe '#generate_password_reset_link' do
    it 'should return a valid url' do
      bobby.generate_verification_digest
      expect(bobby.generate_password_reset_link).to match(URI::regexp)
    end
  end

  describe '#follow' do
    let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
    it 'should follow another user' do
      admin_bobby.follow(bobby)
      expect(User.find(bobby.id).follows.map(&:following)).to include(admin_bobby)
      expect(User.find(admin_bobby.id).followers.map(&:user)).to include(bobby)
    end
  end

  describe '#ban' do
    let(:post) { FactoryGirl.create(:post, user: bobby) }
    it 'should ban the user' do
      bobby.ban("dick", 1.week.from_now, post)
      expect(User.find(bobby.id).role.name).to eq("banned")
    end
    context 'when a ban is extended' do
      it 'should ban the user but preserve their old role in the ban' do
        old_id = bobby.role_id
        bobby.ban("dick", 1.week.from_now, post)
        bobby.ban("serious dick", 2.weeks.from_now, post)
        expect(User.find(bobby.id).bans.first.role_id).to eq(old_id)
      end
    end
  end
end