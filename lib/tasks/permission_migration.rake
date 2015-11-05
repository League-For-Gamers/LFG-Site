namespace :db do
  task :permission_migration => :environment do
    # Roles
    admin = Role.find_or_create_by(id: 1, name: "administrator")
    moderator = Role.find_or_create_by(id: 2, name: "moderator")
    default = Role.find_or_create_by(id: 3, name: "default")
    banned = Role.find_or_create_by(id: 4, name: "banned")

    # Permissions
    p1 = Permission.find_or_create_by(name: "can_create_official_posts")
    p2 = Permission.find_or_create_by(name: "can_edit_all_users_posts")
    p3 = Permission.find_or_create_by(name: "can_ban_users")
    p4 = Permission.find_or_create_by(name: "can_create_post")
    p5 = Permission.find_or_create_by(name: "can_edit_own_posts")
    p6 = Permission.find_or_create_by(name: "can_send_private_messages")
    p7 = Permission.find_or_create_by(name: "can_delete_all_posts")
    p8 = Permission.find_or_create_by(name: "can_create_group")
    p9 = Permission.find_or_create_by(name: "can_update_group")
    

    # Admin permissions
    admin.permissions << p1 unless admin.permissions.map(&:name).include? p1.name
    admin.permissions << p2 unless admin.permissions.map(&:name).include? p2.name
    admin.permissions << p3 unless admin.permissions.map(&:name).include? p3.name
    admin.permissions << p4 unless admin.permissions.map(&:name).include? p4.name
    admin.permissions << p5 unless admin.permissions.map(&:name).include? p5.name
    admin.permissions << p6 unless admin.permissions.map(&:name).include? p6.name
    admin.permissions << p7 unless admin.permissions.map(&:name).include? p7.name
    admin.permissions << p8 unless admin.permissions.map(&:name).include? p8.name
    admin.permissions << p9 unless admin.permissions.map(&:name).include? p9.name
    admin.save

    # Moderator permissions
    moderator.permissions << p2 unless moderator.permissions.map(&:name).include? p2.name
    moderator.permissions << p3 unless moderator.permissions.map(&:name).include? p3.name
    moderator.permissions << p4 unless moderator.permissions.map(&:name).include? p4.name
    moderator.permissions << p5 unless moderator.permissions.map(&:name).include? p5.name
    moderator.permissions << p6 unless moderator.permissions.map(&:name).include? p6.name
    moderator.permissions << p7 unless moderator.permissions.map(&:name).include? p7.name
    moderator.permissions << p8 unless moderator.permissions.map(&:name).include? p8.name
    moderator.save

    # Default permissions
    default.permissions << p4 unless default.permissions.map(&:name).include? p4.name
    default.permissions << p5 unless default.permissions.map(&:name).include? p5.name
    default.permissions << p6 unless default.permissions.map(&:name).include? p6.name
    default.permissions << p8 unless default.permissions.map(&:name).include? p8.name
    default.save
  end
  task :set_default_user_role => :environment do
    User.where(role: nil).each{|x| x.role=Role.find_by(name: 'default');x.save}
  end
end