class GroupMembership < ActiveRecord::Base
  belongs_to :group, counter_cache: :membership_count
  belongs_to :user

  enum role: [:owner, :administrator, :moderator, :member, :banned, :unverified, :invited]

  validates :role, presence: true
  validate :validates_ownership_uniqueness

  PLIST = ["can_create_post", # 0
           "can_edit_own_posts", # 1
           "can_view_group_members", # 2
           "can_ban_users", # 3
           "can_create_official_posts", # 4
           "can_edit_group_member_roles", # 5
           "can_update_group", # 6
           "can_delete_group"] # 7

  def self.get_permission(membership, group = nil)
    permissions = []

    if !membership
      if group.privacy == "public_group" and group.post_control == "public_posts" and group.membership != "owner_verified"
        # Create post, edit own posts, view members
        permissions = [PLIST[0], PLIST[1], PLIST[2]]
      end
      # If we go any further, we'll run into methods for classes that don't exist.
      return permissions
    end
    if ["banned"].include? membership.role
      # Return empty permissions
      return permissions
    end

    case membership.group.post_control
    when "public_posts"
      # Create post, edit own posts
      permissions += [PLIST[0], PLIST[1]]
    when "members_only_post"
      case membership.role
      when "owner", "administrator", "moderator", "member"
        permissions += [PLIST[0], PLIST[1]]
      end
    when "management_only_post"
      case membership.role
      when "owner", "administrator", "moderator"
        permissions += [PLIST[0], PLIST[1]]
      end
    end

    case membership.role
    when "owner"
      # View members, Ban users, create official posts, edit roles, update group, delete group
      permissions += [PLIST[2], PLIST[3], PLIST[4], PLIST[5], PLIST[6], PLIST[7]]
    when "administrator"
      # View members, Ban users, create official posts, edit roles, update group
      permissions += [PLIST[2], PLIST[3], PLIST[4], PLIST[5], PLIST[6]]
    when "moderator"
      # View members, Ban users
      permissions += [PLIST[2], PLIST[3]]
    when "member"
      # View membership
      permissions += [PLIST[2]]
    when "unverified"
    end
    
    permissions
  end

  def self.has_global_permission?(permission, list, user)
    retval = false
    
    case permission
    when Array
      permission.each do |p|
        # Eg can_edit_own_posts becomes can_edit_all_users_posts
        global_permission = p.sub("_own_", "_all_users_")
        retval = (self.has_permission?(p, list) ? true : retval)
        retval = (self.has_permission?(global_permission, list, user) ? true : retval)
      end
    when String
      global_permission = permission.sub("_own_", "_all_users_")
      retval = (self.has_permission?(permission, list) ? true : retval)
      retval = (self.has_permission?(global_permission, list, user) ? true : retval)
    end

    return retval
  end

  def self.has_permission?(permission, list, user = nil)
    retval = false

    # Something fucked up and the user is out of the game entirely. No permission granted.
    return false if !user.nil? and user.role.nil?

    case permission 
    when Array
      permission.each do |p|
        # Don't return false, but return the existing retval, so we dont overwrite it.
        retval = (user.role.has_permission?(p) ? true : retval) unless user.nil?
        retval = (list.include?(p) ? true : retval) unless list.nil?
      end
    when String
      retval = (user.role.has_permission?(permission) ? true : retval) unless user.nil?
      retval = (list.include?(permission) ? true : retval) unless list.nil?
    end
    
    return retval
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

      Notification.create(user: self.user, variant: Notification.variants["group_ban"], group: self.group, data: {ban: ban.id})
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
      Notification.create(user: self.user, variant: Notification.variants["group_unban"], group: self.group, data: {ban: ban.id})
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
