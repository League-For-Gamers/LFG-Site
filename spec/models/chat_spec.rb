require 'rails_helper'

RSpec.describe Chat, type: :model do
  let(:bobby) { FactoryGirl.create(:user)}
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:chat) { FactoryGirl.create(:chat, users: [bobby, admin_bobby])}
  it 'should generate an encryption key on creation' do
    expect(chat.key).to_not be_empty
  end

  it 'should retain the same encryption key when saving' do
    old_key = chat.key
    chat.save
    expect(chat.key).to eq(old_key)
  end
end
