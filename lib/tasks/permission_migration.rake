require 'active_support/inflector'
def get_permission(name)
  Permission.find_or_create_by(name: name)
end

def set_permission(permission, role)
  role.permissions << permission unless role.permissions.map(&:name).include? permission.name
end

def set_mass_permission(permission_array, role)
  puts "\e[33mSetting permissions for \e[34m#{role.name.capitalize}\e[0m: \e[36m#{permission_array.map(&:name).map(&:titleize).join("\e[0m, \e[36m")}\e[0m" unless Rails.env.test?
  permission_array.each do |permission|
    set_permission(permission, role)
  end
  puts '' unless Rails.env.test?
end

namespace :db do
  task :permission_migration => :environment do
    # Roles
    admin = Role.find_or_create_by(id: 1, name: "administrator")
    moderator = Role.find_or_create_by(id: 2, name: "moderator")
    default = Role.find_or_create_by(id: 3, name: "default")
    banned = Role.find_or_create_by(id: 4, name: "banned")

    # Permissions
    p1  = get_permission("can_create_official_posts")
    p2  = get_permission("can_edit_all_users_posts")
    p3  = get_permission("can_ban_users")
    p4  = get_permission("can_create_post")
    p5  = get_permission("can_edit_own_posts")
    p6  = get_permission("can_send_private_messages")
    p7  = get_permission("can_delete_all_posts")
    p8  = get_permission("can_create_group")
    p9  = get_permission("can_update_group")
    p10 = get_permission("can_join_group")
    p11 = get_permission("can_delete_group")
    p12 = get_permission("can_view_group_members")
    p13 = get_permission("can_edit_group_member_roles")
    
    # Admin permissions
    set_mass_permission(
      [p1,p2,p3,p4,p5,p6,p7,p8,p9,p10,p11,p12,p13],
      admin)
    admin.save


    # Moderator permissions
    set_mass_permission(
      [p2,p3,p4,p5,p6,p7,p8,p10,p12],
      moderator)
    moderator.save

    # Default permissions
    set_mass_permission(
      [p4,p5,p6,p8,p10],
      default)
    default.save
  end

  task :set_default_user_role => :environment do
    User.where(role: nil).each{|x| x.role=Role.find_by(name: 'default');x.save}
  end
end