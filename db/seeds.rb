# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

u = User.create(id: 1, username: "admin", password: "admin", email: "admin@admin.com", email_confirm: "admin@admin.com", role: Role.find_by(name: "administrator"))
g = Group.create(id: 1, title: "League for Gamers", description: "Welcome to the League for Gamers", privacy: :public_group, membership: :public_membership, official: true)
m = GroupMembership.create(group: g, user: u, role: :owner)

Post.create(body: "Welcome to the League for Gamers!", user: u, official: true)
Post.create(body: "Welcome to the League for Gamers group!", user: u, group: g)