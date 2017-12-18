require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:group) { FactoryBot.create(:group) }
  let(:bobby) { FactoryBot.create(:user) }
  let(:admin_bobby) { FactoryBot.create(:administrator_user)}
  let(:notification) { FactoryBot.create(:notification, variant: "group_ban", user: bobby, group: group) }

  it 'has a valid factory' do
    expect(notification).to be_valid
    expect(notification.read).to eq(false)
  end
end
