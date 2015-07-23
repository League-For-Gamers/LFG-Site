require 'rails_helper'

RSpec.describe PrivateMessage, type: :model do
  let(:bobby) { FactoryGirl.create(:user)}
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:chat) { FactoryGirl.create(:chat, users: [bobby, admin_bobby])}

  it 'should create an error when a user isnt part of a chat but tries to create a message' do
    third_user = FactoryGirl.create(:user, username: "new_user", display_name: nil, email: "a@b.com", email_confirm: "a@b.com")
    message = FactoryGirl.build(:private_message, chat: chat, user: third_user)
    expect(message).to_not be_valid
    expect(message.errors.count).to eq(1)
  end

  it 'should encrypt private messages' do
    body = "body goes here"
    message = FactoryGirl.create(:private_message, chat: chat, user: bobby, body: body)
    expect(message).to be_valid
    expect(message.body).to_not eq(body)
    expect(message.decrypted_body).to eq(body)
  end
end
