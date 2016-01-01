require 'rails_helper'

RSpec.describe Notification, type: :model do
  let(:group) { FactoryGirl.create(:group) }
  let(:bobby) { FactoryGirl.create(:user) }
  let(:admin_bobby) { FactoryGirl.create(:administrator_user)}
  let(:notification) { FactoryGirl.create(:notification, variant: "group_ban", user: bobby, group: group) }

  it 'has a valid factory' do
    expect(notification).to be_valid
    expect(notification.acknowledged).to eq(false)
  end

  describe '#resolve_url' do
    it 'should return valid urls for all variants' do
      notification.variant = :group_invite
      expect(notification.resolve_url).to include(notification.group.slug)
      expect(notification.resolve_url).to include("members")
      notification.variant = :group_invited
      expect(notification.resolve_url).to include(notification.group.slug)
      expect(notification.resolve_url).to include("join")
      notification.variant = :group_accepted
      expect(notification.resolve_url).to include(notification.group.slug)
      notification.variant = :group_ban
      expect(notification.resolve_url).to include(notification.group.slug)
      notification.variant = :group_unban
      expect(notification.resolve_url).to include(notification.group.slug)
      notification.variant = :ban
      expect(notification.resolve_url).to include("/")
      notification.variant = :unban
      expect(notification.resolve_url).to include("/")
    end
  end

  describe '#resolve_message' do
    it 'should return a valid message for all variants' do
      notification.variant = :group_invite
      display_name = admin_bobby.display_name || admin_bobby.username
      notification.message = display_name
      expect(notification.resolve_message.downcase).to include("join")
      expect(notification.resolve_message.downcase).to include("requested")
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include(notification.group.title.downcase)
      notification.variant = :group_invited
      expect(notification.resolve_message.downcase).to include("invited")
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include(notification.group.title.downcase)
      notification.variant = :group_accepted
      expect(notification.resolve_message.downcase).to include("accepted")
      expect(notification.resolve_message.downcase).to include(notification.group.title.downcase)
      notification.variant = :group_ban
      notification.message = "for 24 days by #{display_name}: wanker"
      expect(notification.resolve_message.downcase).to include(notification.group.title.downcase)
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include("banned")
      notification.variant = :group_unban
      notification.message = "by #{display_name}: not a wanker"
      expect(notification.resolve_message.downcase).to include(notification.group.title.downcase)
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include("unbanned")
      notification.variant = :ban
      notification.message = "for 24 days by #{display_name}: wanker"
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include("banned")
      notification.variant = :unban
      notification.message = "by #{display_name}: not a wanker"
      expect(notification.resolve_message.downcase).to include(notification.message.downcase)
      expect(notification.resolve_message.downcase).to include("unbanned")
    end
  end
end
