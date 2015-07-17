namespace :db do
  task :permission_migration => :environment do
    # Roles
    admin = Role.find_or_create_by(id: 1, name: "administrator")
    moderator = Role.find_or_create_by(id: 2, name: "moderator")

    # Permissions
    p1 = Permission.find_or_create_by(name: "can_create_official_posts")
    p2 = Permission.find_or_create_by(name: "can_edit_all_users_posts")
    p3 = Permission.find_or_create_by(name: "can_ban_users")

    # Admin permissions
    admin.permissions << p1 unless admin.permissions.map(&:name).include? "can_create_official_posts"
    admin.permissions << p2 unless admin.permissions.map(&:name).include? "can_edit_all_users_posts"
    admin.permissions << p3 unless admin.permissions.map(&:name).include? "can_ban_users"
    admin.save

    # Moderator permissions
    moderator.permissions << p2 unless moderator.permissions.map(&:name).include? "can_edit_all_users_posts"
    moderator.permissions << p3 unless moderator.permissions.map(&:name).include? "can_ban_users"
    moderator.save
  end
end