require 'rails_helper'

RSpec.describe Post, type: :model do
  let(:post) { FactoryGirl.create(:post) }
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
      post.body = "Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝"
      post.valid? # Run it thought the validators
      expect(post.body).to eq("ZalgoString")
      expect(post.body).to_not eq("Z̉̌͌̿̓́҉̛̪̠̜̗̺͎̬̻̪̻͇̭͜ͅa̛͒̾̄ͦ̄̓͐̆ͨ̂ͦ͠͠҉̭͙͎̳ḽ̵̶̸̱͎͖̰͙̤͙̩̠̹͈̻̽͒̓ͧͨ͊̏͛ͩ̎̍̚͟ͅg̡̩͎̘̣̫̠͂͋̋̃̅͑̆ͭ̑̄̂͛͟͜ö̥̱͍̳̣̬̭͍̯̬̯̣͍̩͉̠͎̑̈ͤͪ̏̋͋̀ͦͦͥ̕͟ͅS̶̵̴̱͙̦̝̱͎͇̹͓̙̺̠̱̣̖͒͒̍̈́̆̐̈͛ͫ͗ͮt̺̦̙̱̫̘̱̹̭͎͚͖̫̼́͂ͣ̊̋̒̍͟͜r̷̨̡̭͙̘͇̳̦̼̭̥͙͈̭̬͖̳ͯ̅̇̄̂̈͆̎͑ͤ̋̕͜ì̡̬͎͇͎̤̜̝̮̠͙̘͍̊͋̿ͥ̚͢͞n̠͔͔̠̱̦͓̲͔̫̯͕̤̒̒͌ͤ̓ͬͥ̄̾͌͟͡ͅg̵ͪͩ̈͋ͨ̓̈̋̅ͨ͊̈͗ͫ͐ͫ͢͏̡̛̜̖̟̝͓͔̦̙͎̬̜͉̥͉̠̤̱̩̝")
    end
  end
end
