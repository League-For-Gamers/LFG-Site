class Role < ActiveRecord::Base
  validates :name, presence: true

  PLIST = [ "can_create_official_posts",
            "can_edit_all_users_posts",
            "can_ban_users",
            "can_create_post",
            "can_edit_own_posts",
            "can_send_private_messages",
            "can_delete_all_posts",
            "can_create_group",
            "can_update_group",
            "can_join_group",
            "can_delete_group",
            "can_view_group_members",
            "can_edit_group_member_roles"]

  def get_permissions
    permissions = []
    case self.name
    when "administrator"
      permissions += PLIST # Every permission.
    when "moderator"
      # Edit all, Ban users, create posts, edit own, private messages, delete all, create group, join group, view members
      permissions += [PLIST[1], PLIST[2], PLIST[3], PLIST[4], PLIST[5], PLIST[6], PLIST[7], PLIST[9], PLIST[11]]
    when "default"
      # Create posts, edit own, private messages, create groups, join groups.
      permissions += [PLIST[3], PLIST[4], PLIST[5], PLIST[7], PLIST[9]]
    when "banned"
      # none.
    end
    return permissions
  end

  def has_permission?(permission)
    permissions = self.get_permissions
    permissions.include? permission
  end
end
