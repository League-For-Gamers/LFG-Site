require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:post) { FactoryGirl.create(:post) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  it "has a valid factory" do
    expect(post).to be_valid
  end
  it "fails to validate on a post with a body larger than 500 characters" do
    body = ""
    300.times { body << "test test "}
    post = FactoryGirl.build(:post, body: body)
    expect(post).to_not be_valid
  end

  context 'when entering zalgo in a post' do
    it 'is removed from body' do
      zalgostring = "Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝"
      post.body = zalgostring
      post.valid? # Run it thought the validators
      expect(post.body).to eq("ZalgoString")
      expect(post.body).to_not eq(zalgostring)
    end
  end

  context 'when destroyed' do
    it 'any associated bans have their post association wiped' do
      post.user.ban("dicks", 1.week.from_now, admin_bobby, post)
      expect(post.bans.count).to eq(1)
      ban = post.bans.first
      post.destroy
      expect(Ban.find(ban.id).post).to be(nil)
    end
  end

  describe "limits on the size of posts" do

    it "should accept a post with exactly 512 characters" do
      post = FactoryGirl.build(:post, body: "a"*512)
      expect(post).to be_valid
    end

    it "should accept a post with exactly 511 characters" do
      post = FactoryGirl.build(:post, body: "a"*511)
      expect(post).to be_valid
    end

    it "should NOT accept a post with exactly 513 characters" do
      post = FactoryGirl.build(:post, body: "a"*513)
      expect(post).to_not be_valid
    end

  end

end
