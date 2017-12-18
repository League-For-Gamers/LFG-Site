require 'rails_helper'

RSpec.describe User, :type => :model do
  let(:bobby) { FactoryBot.create(:user) }
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}
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
    let(:bobby) { FactoryBot.create(:user_with_skill)}
    it "has a coding skill" do
      expect(bobby.skills.length).to be > 0    
    end
  end

  context 'when it has a game' do
    let(:bobby) { FactoryBot.create(:user_with_game)}
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
    let(:bobby) { FactoryBot.build(:user, password: nil) }
    it "is not valid" do
      expect(bobby).to_not be_valid
    end
  end

  context 'when entering an email' do
    let(:email) { "test@email.com" }
    let(:bobby) { FactoryBot.create(:user, email: email, email_confirm: email) }
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
      new_user = FactoryBot.build(:user, username: "NotBobby", display_name: "Not Bobby", email: bobby.decrypted_email, email_confirm: email)
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

  describe '#can_modify_post?' do
    let(:bobby) { FactoryBot.create(:user) }
    let(:admin_bobby) { FactoryBot.create(:administrator_user) }

    it 'should allow for an unbanned user to edit their own post' do
      expect(bobby.can_modify_post?(bobby)).to be(true)
    end

    it 'should allow an admin to modify a users post' do
      expect(admin_bobby.can_modify_post?(bobby)).to be(true)
    end

    it 'should forbid a normal user from modifying another users' do
      expect(bobby.can_modify_post?(admin_bobby)).to be(false)
    end

    it 'should forbid a banned user from modifying their post' do
      bobby.ban("test", 1.week.from_now, admin_bobby)
      expect(bobby.can_modify_post?(bobby)).to be(false)
    end
  end

  describe '#has_global_permission?' do
    let(:bobby) { FactoryBot.create(:user) }
    let(:admin_bobby) { FactoryBot.create(:administrator_user) }

    context 'when passing an array of permissions' do
      it 'should return true when a user has either a local or global permission given' do
        expect(bobby.has_global_permission?(['can_edit_own_posts', 'can_delete_own_posts'])).to be(true)
        # The user now only has can_edit_all_users_posts. 
        bobby.role = Role.find_by(name: 'testing')
        bobby.save
        expect(bobby.has_global_permission?(['can_edit_own_posts', 'can_delete_own_posts'])).to be(true)
      end

      it 'should return false when a user has neither local or global permissions' do
        bobby.ban("test", 1.week.from_now, admin_bobby)
        expect(bobby.has_global_permission?(['can_edit_own_posts', 'can_delete_own_posts'])).to be(false)
      end
    end

    context 'when passing a single permission' do
      it 'should return true when a user has either a local or global permission' do
        expect(bobby.has_global_permission?('can_edit_own_posts')).to be(true)
        # The user now only has can_edit_all_users_posts. 
        bobby.role = Role.find_by(name: 'testing')
        bobby.save
        expect(bobby.has_global_permission?('can_edit_own_posts')).to be(true)
      end

      it 'should return false when a user has neither local or global permission' do
        bobby.ban("test", 1.week.from_now, admin_bobby)
        expect(bobby.has_global_permission?('can_edit_own_posts')).to be(false)
      end
    end
  end

  describe '#has_permission?' do
    let(:bobby) { FactoryBot.create(:user) }

    context 'when passing a single permission' do
      it 'should return true for a user that has the permission' do
        permission = bobby.role.get_permissions.first
        expect(bobby.has_permission?(permission)).to be(true)
      end

      it 'should return false for when the user does not have a permission' do
        expect(bobby.has_permission?("fake_permission")).to be(false)
      end
    end

    context 'when passing an array of permissions' do
      it 'should return true for a user that has one of the listed permissions' do
        permission = bobby.role.get_permissions.first
        expect(bobby.has_permission?(["doesnt_exist", permission])).to be(true)
      end

      it 'should return false for when the user does not have any given permission' do
        expect(bobby.has_permission?(["doesnt_exist", "also_doesnt"])).to be(false)
      end
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
    let(:admin_bobby) { FactoryBot.create(:administrator_user)}
    it 'should follow another user' do
      bobby.follow(admin_bobby)
      expect(User.find(bobby.id).follows.map(&:following)).to include(admin_bobby)
      expect(User.find(admin_bobby.id).followers.map(&:user)).to include(bobby)
    end
  end

  describe '#follow?' do
    it 'should return true if the user is following the other' do
      bobby.follow(admin_bobby)
      expect(bobby.follow?(admin_bobby)).to be true
    end

    it 'should return false if the user is following the other' do
      expect(admin_bobby.follow?(bobby)).to be false
    end
  end

  describe '#ban' do
    let(:post) { FactoryBot.create(:post, user: bobby) }
    it 'should ban the user' do
      bobby.ban("dick", 1.week.from_now, admin_bobby, post)
      expect(User.find(bobby.id).role.name).to eq("banned")
    end
    context 'when a ban is extended' do
      it 'should ban the user but preserve their old role in the ban' do
        old_id = bobby.role_id
        bobby.ban("dick", 1.week.from_now, admin_bobby, post)
        bobby.ban("serious dick", 2.weeks.from_now, admin_bobby, post)
        expect(User.find(bobby.id).bans.first.role_id).to eq(old_id)
      end
    end
    it 'should raise an error when a ban cannot be saved' do
      expect { bobby.ban("dick", 1.week.from_now, nil) }.to raise_error(Exception)
    end
  end
end