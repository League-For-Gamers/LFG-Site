require 'active_support/inflector'

namespace :db do
  task :permission_migration => :environment do
    # Roles
    admin = Role.find_or_create_by(id: 1, name: "administrator")
    moderator = Role.find_or_create_by(id: 2, name: "moderator")
    default = Role.find_or_create_by(id: 3, name: "default")
    banned = Role.find_or_create_by(id: 4, name: "banned")
  end

  task :object_migration => :environment do
    # :nocov:
    lfg_group = Group.find_or_create_by(id: 1, title: "League for Gamers", privacy: :public_group, membership: :public_membership, official: true)
    # :nocov:
  end

  task :everyone_join_lfg => :environment do
    # :nocov:
    g = Group.find_by(slug: "league_for_gamers")
    User.all.each do |u|
      GroupMembership.create(user: u, group: g, role: :member) unless !!GroupMembership.find_by(user: u, group: g)
    end
    posts = Post.where(group: nil)
    posts.each do |p|
      p.group = g unless p.official?
      p.save
    end
    # :nocov:
  end

  task :set_default_user_role => :environment do
    User.where(role: nil).each{|x| x.role=Role.find_by(name: 'default');x.save}
  end

  task :set_banner_id_to_wingar => :environment do
    w = User.where("lower(username) = ?", "wingar").first
    Ban.all.each do |ban|
      ban.banner_id = w.id
      ban.save
    end
  end

  task :set_ban_duration_string => :environment do
    require 'action_view'
    require 'active_support/all'
    Ban.all.each do |ban|
      ban.duration_string = ActionView::Base.new.distance_of_time_in_words ban.created_at, ban.end_date
      ban.save
    end
  end
 end