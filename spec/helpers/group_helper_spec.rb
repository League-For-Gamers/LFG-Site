require 'rails_helper'

RSpec.describe GroupHelper, type: :helper do
  let(:bobby) { FactoryGirl.create(:user) }
  let(:group) { FactoryGirl.create(:group) }
  let(:membership) { FactoryGirl.create(:group_membership, user: bobby, group: group) }
  describe '#post_time_ago' do
    let(:post) {FactoryGirl.create(:post, user: bobby, group: group)}
    context 'when post has not been updated' do
      it 'should return a string that does not reflect an edited post' do
        expect(helper.group_post_time_ago(post).downcase).to_not include("edited")
      end
    end
    context 'when post has been updated' do
      before do
        post.updated_at = post.created_at + 1.days
      end
      it 'should return a string that reflects an edited post' do
        expect(helper.group_post_time_ago(post).downcase).to include("edited")
      end
    end
  end

  describe '#universal_permission_check' do
    # This has a lot more bootstrap than I would have expected. Yikes.
    context 'when a user has a global permission' do
      it 'should return true' do
        expect(helper.universal_permission_check("can_create_post", {user: bobby})).to eq(true)
      end
    end
    context 'when a user has a group permission' do
      before do
        membership.role = :owner
        membership.save
      end

      it 'should return true' do
        permissions = GroupMembership.get_permission(membership, group)
        expect(helper.universal_permission_check("can_edit_group_member_roles", {permissions: permissions, user: bobby})).to eq(true)
      end
    end
  end

end
