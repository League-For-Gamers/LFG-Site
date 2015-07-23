require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:bobby) { FactoryGirl.create(:user)}
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:chat) { FactoryGirl.create(:chat, users: [bobby, admin_bobby])}
  let(:third_user) { FactoryGirl.create(:user, username: "new_user", display_name: nil, email: "a@b.com", email_confirm: "a@b.com") }
  before do
    session[:user] = bobby.id
  end

  describe 'GET /messages' do
    it 'should list all chats the user is involved in' do
      chat.save
      get :index
      expect(assigns(:chats)).to include(chat)
    end
  end

  describe 'GET /messages/:id' do
    it 'should show all the messages in a chat' do
      get :show, id: chat.id
      expect(assigns(:chat)).to eq(chat)
    end
    it 'should throw a 404 when the user does not belong in the chat' do
      
      new_chat = FactoryGirl.create(:chat, users: [third_user, admin_bobby])
      get :show, id: new_chat.id
      expect(response.status).to eq(404)
    end
    it 'should throw a 404 when the chat ID doesnt exist' do
      get :show, id: "invalid_id"
      expect(response.status).to eq(404)
    end
  end

  describe 'PUT /messages/:id' do
    it 'should create a new message in the chat' do
      put :create_message, id: chat.id, private_message: { body: "new body" }
      expect(response).to redirect_to("/messages/#{chat.id}")
      expect(Chat.find(chat.id).private_messages.map(&:decrypted_body)).to include("new body")
    end

    it 'should reject the message if its invalid' do
      body = ""
      500.times { body << "test " }
      put :create_message, id: chat.id, private_message: { body: body }
      expect(response).to_not redirect_to("/messages/#{chat.id}")
      expect(flash[:alert]).to be_present
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT /messages' do
    it 'should create a new chat session between two users' do
      put :create_chat, private_message: { body: "body", user: {"0" => {id: third_user.id } } }
      expect(assigns(:message)).to be_valid
      expect(response).to redirect_to(/\/messages\/\d+/)
    end
    it 'should fail gracefully when errors are found' do
      body = ""
      500.times { body << "test " }
      put :create_chat, private_message: { body: body, user: {"0" => {id: third_user.id } } }
      expect(assigns(:message)).to_not be_valid
      expect(response).to render_template('user/direct_message')
    end
  end
end
