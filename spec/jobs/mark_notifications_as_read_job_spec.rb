require 'rails_helper'

RSpec.describe MarkNotificationsAsReadJob, type: :job do
  include ActiveJob::TestHelper
  let(:bobby) { FactoryGirl.create(:user)}
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}

  it 'should mark notifications as acknowledged' do
    n1 = bobby.create_notification(:mention)
    n2 = admin_bobby.create_notification(:mention)
    expect(n1.acknowledged).to eq(false)
    expect(n2.acknowledged).to eq(false)
    perform_enqueued_jobs { MarkNotificationsAsReadJob.perform_now([n1,n2]) }
    expect(Notification.find(n1.id).acknowledged).to eq(true)
    expect(Notification.find(n2.id).acknowledged).to eq(true)
  end

  it 'should not mark already acknowledged notifications as false' do
    n = Notification.create(variant: Notification.variants["mention"], user: bobby, acknowledged: true)
    expect(n.acknowledged).to eq(true)
    perform_enqueued_jobs { MarkNotificationsAsReadJob.perform_now([n]) }
    expect(Notification.find(n.id).acknowledged).to eq(true)
  end
end
