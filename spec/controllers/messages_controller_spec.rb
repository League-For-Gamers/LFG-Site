require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  include ActiveJob::TestHelper
  let(:bobby) { FactoryBot.create(:user)}
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}
  let(:chat) { FactoryBot.create(:chat, users: [bobby, admin_bobby])}
  let(:notification) { FactoryBot.create(:notification, user: bobby) }
  let(:third_user) { FactoryBot.create(:user, username: "new_user", display_name: nil, email: "a@b.com", email_confirm: "a@b.com") }
  before do
    session[:user] = bobby.id
  end

  describe 'GET /messages' do
    it 'should list all chats the user is involved in' do
      chat.save
      notification.save
      get :index
      expect(assigns(:chats)).to include(chat)
      expect(assigns(:notifications)).to include(notification)
    end
  end

  describe 'POST /messages' do
    before do
      notification.save
      chat.save
    end
    it 'should return a page of notifications' do
      post :index_ajax, params: {source: "notifications", page: 0} 
      expect(assigns(:notifications)).to_not be_empty
    end
    it 'should return a page of chats' do
      post :index_ajax, params: {source: "messages", page: 0}
      expect(assigns(:chats)).to include(chat)
    end
    it 'should fail gracefully when given missing or invalid parameters' do
      post :index_ajax
      expect(response.status).to eq(403)
      post :index_ajax, params: {source: "messages"}
      expect(response.status).to eq(403)
      post :index_ajax, params: {source: "invalid", page: 0}
      expect(response.status).to eq(403)
    end
  end

  describe 'GET /messages/:id' do
    it 'should show all the messages in a chat' do
      get :show, params: { id: chat.id }
      expect(assigns(:chat)).to eq(chat)
    end
    it 'should throw a 404 when the user does not belong in the chat' do
      new_chat = FactoryBot.create(:chat, users: [third_user, admin_bobby])
      get :show, params: { id: new_chat.id }
      expect(response.status).to eq(404)
    end
    it 'should throw a 404 when the chat ID doesnt exist' do
      get :show, params: { id: "invalid_id" }
      expect(response.status).to eq(404)
    end
  end

  describe 'GET /messages/:id/newer' do
    it 'should get messages newer than the last' do
      2.times { FactoryBot.create(:private_message, user: bobby, chat: chat) }
      last_post = chat.private_messages.first
      new_post = FactoryBot.create(:private_message, user: admin_bobby, chat: chat, created_at: Time.now + 1.minute)
      get :new_messages, params: { id: chat.id, timestamp: last_post.created_at }
      expect(assigns(:messages)).to include(new_post)
      expect(enqueued_jobs.size).to eq(1)
    end
    it 'should return empty when there are no new posts' do
      2.times { FactoryBot.create(:private_message, user: bobby, chat: chat) }
      last_post = chat.private_messages.first
      get :new_messages, params: { id: chat.id, timestamp: last_post.created_at }
      expect(response.status).to eq(200)
    end
  end

  describe 'GET /messages/:id/older' do
    it 'should get messages older than the first' do
      10.times { FactoryBot.create(:private_message, user: bobby, chat: chat) }
      new_post = FactoryBot.create(:private_message, user: admin_bobby, chat: chat, created_at: Time.now - 1.year)
      last_post = chat.private_messages.last
      get :older_messages, params: { id: chat.id, timestamp: last_post.created_at }
      expect(assigns(:messages)).to include(new_post)
    end
  end

  describe 'PUT /messages/:id' do
    it 'should create a new message in the chat' do
      put :create_message, params: { id: chat.id, private_message: { body: "new body" } }
      expect(response).to redirect_to("/messages/#{chat.id}")
      expect(Chat.find(chat.id).private_messages.map(&:decrypted_body)).to include("new body")
    end

    it 'should reject the message if its invalid' do
      new_post = FactoryBot.create(:private_message, user: admin_bobby, chat: chat, created_at: Time.now)
      body = ""
      500.times { body << "test " }
      put :create_message, params: { id: chat.id, private_message: { body: body } }
      expect(response).to_not redirect_to("/messages/#{chat.id}")
      expect(flash[:alert]).to be_present
      expect(assigns(:messages)).to be_present
      expect(assigns(:messages).map(&:decrypted_body)).to_not include(body)
      expect(response).to render_template(:show)
    end
  end

  describe 'PUT /messages' do
    it 'should create a new chat session between two users' do
      put :create_chat, params: {  private_message: { body: "body", user: {"0" => {id: third_user.id } } } }
      expect(assigns(:message)).to be_valid
      expect(response).to redirect_to(/\/messages\/\d+/)
    end
    it 'should fail gracefully when errors are found' do
      body = ""
      500.times { body << "test " }
      put :create_chat, params: { private_message: { body: body, user: {"0" => {id: third_user.id } } } }
      expect(assigns(:message)).to_not be_valid
      expect(response).to render_template('user/direct_message')
    end
  end
end
