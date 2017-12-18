require 'rails_helper'

RSpec.describe Chat, type: :model do
  let(:bobby) { FactoryBot.create(:user)}
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}
  let(:chat) { FactoryBot.create(:chat, users: [bobby, admin_bobby])}
  it 'should generate an encryption key on creation' do
    expect(chat.key).to_not be_empty
  end

  it 'should retain the same encryption key when saving' do
    old_key = chat.key
    chat.save
    expect(chat.key).to eq(old_key)
  end

  describe '#new_messages' do
    it 'should return true on a new message being recieved by a user' do
      expect(chat.new_messages(bobby)).to eq(false)
      FactoryBot.create(:private_message, user: admin_bobby, chat: chat)
      expect(chat.new_messages(bobby)).to eq(true)
    end
  end

  describe '#new_messages_count' do
    it 'should return a count of unread messages' do
      chat.update_timestamp(bobby.id)
      FactoryBot.create(:private_message, user: admin_bobby, chat: chat)
      expect(chat.new_messages_count(bobby)).to eq(1)
    end
  end

  describe '#new_messages_since' do
    it 'should return a count of unread messages from a timestamp' do
      FactoryBot.create(:private_message, user: admin_bobby, chat: chat, created_at: Time.now)
      expect(chat.new_messages_since(Time.now - 5.minutes, bobby)).to eq(1)
    end
  end

  context 'when a chat between two users already exists' do
    it 'should throw a validation error' do
      chat.save
      newchat = FactoryBot.build(:chat, users: [bobby, admin_bobby])
      expect(newchat).to_not be_valid
    end
  end
end
