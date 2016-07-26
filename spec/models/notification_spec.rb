require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:group) { FactoryGirl.create(:group) }
  let(:bobby) { FactoryGirl.create(:user) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:notification) { FactoryGirl.create(:notification, variant: "group_ban", user: bobby, group: group) }

  it 'has a valid factory' do
    expect(notification).to be_valid
    expect(notification.read).to eq(false)
  end
end
