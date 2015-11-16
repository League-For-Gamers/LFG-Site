class GroupMembership < ActiveRecord::Base
  belongs_to :group, counter_cache: :membership_count
  belongs_to :user

  enum role: [:owner, :administrator, :moderator, :member, :banned, :unverified]

  validates :role, presence: true
  validate :validates_ownership_uniqueness

  def self.get_permission(membership, group = nil)
    permissions = []

    # Permissions are inherited by higher roles. 
    # I'm pretty sure this can be cleaner.
    if !membership
      if group.privacy == "public_group" and group.membership != "owner_verified"
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
        permissions << Permission.find_by(name: "can_view_group_members")
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
        permissions << Permission.find_by(name: "can_view_group_members")
      end
      if ["member", "moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
        permissions << Permission.find_by(name: "can_view_group_members")
      end
      if ["moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_ban_users")
      end
      if ["owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_official_posts")
        permissions << Permission.find_by(name: "can_update_group")
        permissions << Permission.find_by(name: "can_edit_group_member_roles")
      end
      if ["owner"].include? membership.role
        permissions << Permission.find_by(name: "can_delete_group")
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
        permissions << Permission.find_by(name: "can_edit_group_member_roles")
      end
      if ["owner"].include? membership.role
        permissions << Permission.find_by(name: "can_delete_group")
      end
    when "private_group"
      if ["member", "moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_post")
        permissions << Permission.find_by(name: "can_edit_own_posts")
        permissions << Permission.find_by(name: "can_view_group_members")
      end
      if ["moderator", "owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_ban_users")
      end
      if ["owner", "administrator"].include? membership.role
        permissions << Permission.find_by(name: "can_create_official_posts")
        permissions << Permission.find_by(name: "can_update_group")
        permissions << Permission.find_by(name: "can_edit_group_member_roles")
      end
      if ["owner"].include? membership.role
        permissions << Permission.find_by(name: "can_delete_group")
      end
    end
    permissions
  end

  def self.has_permission?(permission, list)
    return false if list.blank?
    list.map(&:name).include? permission
  end

  def ban(reason, end_date, banner, post = nil)
    if self.role == "banned"
      old_role = Ban.where(user: self.user, group: self.group).where.not(group_role: "banned").order("created_at DESC").first.group_role
    else
      old_role = self.role
    end

    duration_string = ActionView::Base.new.distance_of_time_in_words Time.now, end_date unless end_date.nil?
    duration_string = "permanently" if end_date.nil?

    ban = Ban.new(user: self.user, reason: reason, end_date: end_date, group_role: old_role, group: self.group, duration_string: duration_string, banner: banner)
    ban.post = post unless post.nil?
    if ban.valid?
      ban.save  
      self.role = :banned
      self.save

      notification_message = "for #{ban.duration_string}"
      notification_message = 'until the end of time' if end_date.nil?
      notification_message = "by #{banner.display_name || banner.username}"
      notification_message << ": #{reason}" unless reason.blank?
      self.user.create_notification("group_ban", self.group, notification_message)
    else
      raise ban.errors.full_messages.join(", ")
    end
  end

  def unban(reason, banner, post = nil)
    old_role = Ban.where(user: self.user, group: self.group).where.not(group_role: "banned").order("created_at DESC").first.group_role
    ban = Ban.new(user: self.user, reason: reason, end_date: 1.day.ago, group_role: old_role, group: self.group, banner: banner)
    ban.post = post unless post.nil?
    if ban.valid?
      ban.save
      self.role = old_role
      self.save
      notification_message = "by #{banner.display_name || banner.username}"
      notification_message << ": #{reason}" unless reason.blank?
      self.user.create_notification("group_unban", self.group, notification_message)
    else
      raise ban.errors.full_messages.join(", ")
    end
  end

  private
    def validates_ownership_uniqueness
      return if self.user.role == Role.find_by(name: "administrator") # Global admins can own as many as they want.
      errors.add(:user, "cannot own more than one group") if self.user.group_memberships.map(&:role).include? "owner" and self.role == "owner"
    end
end
