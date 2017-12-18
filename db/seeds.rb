# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

puts "Generating permissions..."
load "#{Rails.root}/lib/tasks/permission_migration.rake"
Rake::Task['db:permission_migration'].invoke

puts "Generating users and group..."
admin = User.create(id: 1, username: "admin", password: "admin", email: "admin@admin.com", email_confirm: "admin@admin.com", role: Role.find_by(name: "administrator"))
user = User.create(id: 2, username: "boring_user", password: "boring_user", email: "boring@user.com", email_confirm: "boring@user.com")
g = Group.create(id: 1, title: "League for Gamers", description: "Welcome to the League for Gamers", privacy: :public_group, membership: :public_membership, official: true)
# Join users to group
admin_membership = GroupMembership.create(group: g, user: admin, role: :owner)
user_membership = GroupMembership.create(group: g, user: user, role: :member)
# User follows admin
user.follow(admin)

puts "Filling group with posts..."
p1 = Post.create(body: "Welcome to the League for Gamers!", user: admin, group: g, official: true)
p2 = Post.create(body: "Welcome to the League for Gamers group!", user: admin, group: g)
# Comments
Post.create(body: "Test comment uno", user: user, group: g, parent: p1)
Post.create(body: "Good to be here!", user: user, group: g, parent: p2)
Post.create(body: "Welcome, @boring_user!", user: admin, group: g, parent: p2)

puts "Filling user feeds with posts..."
p3 = Post.create(body: "Testing feed posts.", user: user)
p4 = Post.create(body: "Testing official feed posts", user: admin, official: true)
p5 = Post.create(body: "Testing non-official feed posts", user: admin)
# Comments
Post.create(body: "Wow great post!", user: user, parent: p4)
Post.create(body: "I know, right?", user: admin, parent: p4)