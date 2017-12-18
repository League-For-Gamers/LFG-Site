require 'rails_helper'

RSpec.describe MarkNotificationsAsReadJob, type: :job do
  include ActiveJob::TestHelper
  let(:bobby) { FactoryBot.create(:user)}
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}

  it 'should mark notifications as read' do
    n1 = Notification.create(user: bobby, variant: Notification.variants["mention"])
    n2 = Notification.create(user: bobby, variant: Notification.variants["mention"])
    expect(n1.read).to eq(false)
    expect(n2.read).to eq(false)
    perform_enqueued_jobs { MarkNotificationsAsReadJob.perform_now([n1,n2]) }
    expect(Notification.find(n1.id).read).to eq(true)
    expect(Notification.find(n2.id).read).to eq(true)
  end

  it 'should not mark already read notifications as false' do
    n = Notification.create(variant: Notification.variants["mention"], user: bobby, read: true)
    expect(n.read).to eq(true)
    perform_enqueued_jobs { MarkNotificationsAsReadJob.perform_now([n]) }
    expect(Notification.find(n.id).read).to eq(true)
  end
end
