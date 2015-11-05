class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  enum role: [:owner, :administrator, :moderator, :member, :banned, :unverified]

  validates :role, presence: true

  def self.get_permission(membership, group = nil)
    permissions = []

    # Permissions are inherited by higher roles. 
    # I'm pretty sure this can be cleaner.
    if !membership
      if group.privacy == "public_group" and group.membership != "owner_verified"
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
      end
      # If we go any further, we'll run into methods for classes that don't exist.
      return permissions
    end
    if ["banned"].include? membership.role
      # Return empty permissions
      return permissions
    end

    case membership.group.privacy
    when "public_group", "members_only_post"
      if ["unverified"].include? membership.role
        permissions << Permission.find_by(name: "can_edit_own_posts")
      end
      if ["member", "moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
      end
      if ["moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_ban_users")
      end
      if ["owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_official_posts")
        permissions << Permission.find_by(name: "can_update_group")
      end
    when "management_only_post"
      if ["member", "moderator", "owner", "unverified", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_edit_own_posts")
      end
      if ["moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_ban_users")
      end
      if ["owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_official_posts")
        permissions << Permission.find_by(name: "can_update_group")
      end
    when "private_group"
      if ["member", "moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
      end
      if ["moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_ban_users")
      end
      if ["owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_official_posts")
        permissions << Permission.find_by(name: "can_update_group")
      end
    end
    permissions
  end

  def self.has_permission?(permission, list)
    return false if list.empty?
    list.map(&:name).include? permission
  end

  def ban(reason, end_date, post = nil)
    if self.role == "banned"
      old_role = Ban.where(user: self.user, group: self.group).where.not(group_role: "banned").order("end_date DESC").first.group_role
    else
      old_role = self.role
    end

    ban = Ban.new(user: self.user, reason: reason, end_date: end_date, group_role: old_role, group: self.group)
    ban.post = post unless post.nil?
    ban.save
    self.role = :banned
    self.save
  end
end
