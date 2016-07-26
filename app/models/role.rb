class Role < ActiveRecord::Base
  validates :name, presence: true

  PLIST = [ "can_create_official_posts", # 0
            "can_edit_all_users_posts", # 1
            "can_ban_users", # 2
            "can_create_post", # 3
            "can_edit_own_posts", # 4
            "can_send_private_messages", # 5
            "can_delete_own_posts", # 6
            "can_delete_all_users_posts", # 7
            "can_create_group", # 8
            "can_update_group", # 9
            "can_join_group", # 10
            "can_delete_group", # 11
            "can_view_group_members", # 12
            "can_edit_group_member_roles"] # 13

  def get_permissions
    permissions = []
    case self.name
    when "administrator"
      permissions += PLIST # Every permission.
    when "moderator"
      # Edit all, Ban users, create posts, edit own, delete own, private messages, delete all, create group, join group, view members
      permissions += [PLIST[1], PLIST[2], PLIST[3], PLIST[4], PLIST[5], PLIST[6], PLIST[7], PLIST[8], PLIST[10], PLIST[12]]
    when "default"
      # Create posts, edit own, private messages, delete own, create groups, join groups.
      permissions += [PLIST[3], PLIST[4], PLIST[5], PLIST[6], PLIST[8], PLIST[10]]
    when "testing"
      permissions += [PLIST[1], PLIST[6]]
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
