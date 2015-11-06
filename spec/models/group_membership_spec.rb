require 'rails_helper'

RSpec.describe GroupMembership, type: :model do
  let(:bobby) { FactoryGirl.create(:user) }
  let(:group) { FactoryGirl.create(:group)}
  let(:membership) { FactoryGirl.create(:group_membership, user: bobby, group: group) }
  describe '#ban' do
    let(:post) { FactoryGirl.create(:post, user: bobby, group: group) }
    it 'should ban the user' do
      membership.ban("dick", 1.week.from_now, post)
      expect(group.group_memberships.find_by(user: bobby).role).to eq("banned")
    end
    context 'when a ban is extended' do
      it 'should ban the user but preserve their old role in the ban' do
        old_role = membership.role
        membership.ban("dick", 1.week.from_now, post)
        membership.ban("serious dick", 2.weeks.from_now, post)
        expect(group.group_memberships.find_by(user: bobby).role).to eq("banned")
        expect(Ban.where(user: bobby, group: group).first.group_role).to eq(old_role)
      end
    end
  end

  describe '#get_permission' do
    context 'when the group is public' do
      context 'but has owner verified membership' do
        before do
          group.membership = :owner_verified
        end
        it 'should not give posting permissions to non-members' do
          permissions = GroupMembership.get_permission(nil, group)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to_not include("can_edit_own_posts")
        end
        it 'should give posting permissions to verified members' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
        it 'should not give posting permissions to unverified members' do
          membership.role = :unverified
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
      end

      it 'should give posting permissions to non members' do
        permissions = GroupMembership.get_permission(nil, group)
        expect(permissions.map(&:name)).to include("can_create_post")
        expect(permissions.map(&:name)).to include("can_edit_own_posts")
      end

      context 'and the user is a member' do
        it 'should give posting permisison to the user' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
      end

      context 'and the user is a moderator' do
        before do
          membership.role = :moderator
        end
        it 'should give the user posting and banning permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
        end
      end

      context 'and the user is the owner' do
        before do
          membership.role = :owner
        end
        it 'should give the user posting, banning and official posting permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
          expect(permissions.map(&:name)).to include("can_create_official_posts")
          expect(permissions.map(&:name)).to include("can_update_group")
        end
      end

      context 'and the user is banned' do
        before do
          membership.role = :banned
        end
        it 'should give the user no permissions' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to_not include("can_edit_own_posts")
          expect(permissions).to be_empty
        end
      end
    end
    context 'when the group is members only post' do
      before do
        group.privacy = :members_only_post
      end
      context 'and the user is not a member' do
        it 'should not give the user posting permissions' do
          permissions = GroupMembership.get_permission(nil, group)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to_not include("can_edit_own_posts")
        end
      end

      context 'and the user is a member' do
        it 'should give posting permisison to the user' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
      end

      context 'and the user is a moderator' do
        before do
          membership.role = :moderator
        end
        it 'should give the user posting and banning permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
        end
      end

      context 'and the user is the owner' do
        before do
          membership.role = :owner
        end
        it 'should give the user posting, banning and official posting permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
          expect(permissions.map(&:name)).to include("can_create_official_posts")
          expect(permissions.map(&:name)).to include("can_update_group")
        end
      end
    end

    context 'when the group is management only post' do
      before do
        group.privacy = :management_only_post
      end
      context 'and the user is not a member' do
        it 'should not give the user posting permissions' do
          permissions = GroupMembership.get_permission(nil, group)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to_not include("can_edit_own_posts")
        end
      end

      context 'and the user is a member' do
        it 'should not give posting permisison to the user' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
      end

      context 'and the user is a moderator' do
        before do
          membership.role = :moderator
        end
        it 'should give the user posting and banning permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
        end
      end

      context 'and the user is the owner' do
        before do
          membership.role = :owner
        end
        it 'should give the user posting, banning and official posting permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
          expect(permissions.map(&:name)).to include("can_create_official_posts")
          expect(permissions.map(&:name)).to include("can_update_group")
        end
      end
    end

    context 'when the group is private' do
      before do
        group.privacy = :private_group
      end
      context 'and the user is not a member' do
        it 'should not give the user posting permissions' do
          permissions = GroupMembership.get_permission(nil, group)
          expect(permissions.map(&:name)).to_not include("can_create_post")
          expect(permissions.map(&:name)).to_not include("can_edit_own_posts")
        end
      end

      context 'and the user is a member' do
        it 'should give posting permisison to the user' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
        end
      end

      context 'and the user is a moderator' do
        before do
          membership.role = :moderator
        end
        it 'should give the user posting and banning permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
        end
      end

      context 'and the user is the owner' do
        before do
          membership.role = :owner
        end
        it 'should give the user posting, banning and official posting permisisons' do
          permissions = GroupMembership.get_permission(membership)
          expect(permissions.map(&:name)).to include("can_create_post")
          expect(permissions.map(&:name)).to include("can_edit_own_posts")
          expect(permissions.map(&:name)).to include("can_ban_users")
          expect(permissions.map(&:name)).to include("can_update_group")
          expect(permissions.map(&:name)).to include("can_create_official_posts")
        end
      end
    end
  end

  describe '#has_permission' do
    let(:permissions) { GroupMembership.get_permission(membership) }
    it 'should return true for a user that has the permission' do
      expect(GroupMembership.has_permission?("can_create_post", permissions)).to be(true)
    end

    it 'should return false for when the user does not have a permission' do
      expect(GroupMembership.has_permission?("fake_permission", permissions)).to be(false)
    end
  end
end
