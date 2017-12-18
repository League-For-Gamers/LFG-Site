require 'rails_helper'

RSpec.describe MessageCountIncrementJob, type: :job do
  include ActiveJob::TestHelper
  let(:bobby) { FactoryBot.create(:user)}
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}
  let(:chat) { FactoryBot.create(:chat, users: [bobby, admin_bobby])}
  it 'should increment the unread message count for users in the chat' do
    expect(bobby.unread_count).to eq(0)
    message = FactoryBot.create(:private_message, user: admin_bobby, chat: chat)
    perform_enqueued_jobs { MessageCountIncrementJob.perform_now(message) }
    expect(User.find(bobby.id).unread_count).to eq(1)
  end
end
