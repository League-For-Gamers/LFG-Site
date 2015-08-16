require 'rails_helper'

RSpec.describe MessageCountResolveJob, type: :job do
  include ActiveJob::TestHelper
  let(:bobby) { FactoryGirl.create(:user)}
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:chat) { FactoryGirl.create(:chat, users: [bobby, admin_bobby])}
  it 'should remove the appropriate number of messages from a users unread_count' do
    expect(bobby.unread_count).to eq(0)
    5.times { FactoryGirl.create(:private_message, user: admin_bobby, chat: chat, created_at: Time.now) }
    bobby.unread_count = 7
    bobby.save
    perform_enqueued_jobs { MessageCountResolveJob.perform_now(chat, bobby, Time.now - 1.year) }
    expect(User.find(bobby.id).unread_count).to eq(2)
  end
end
