class GroupMembership < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  enum role: [:owner, :moderator, :member, :banned]

  validates :role, presence: true

  def get_permission()
    permissions = []

    # Permissions are inherited by higher roles. 
    # I'm pretty sure this can be cleaner.
    if ["banned"].include? self.role
    end
    if ["member", "moderator", "owner"].include? self.role
      permissions << Permission.find_by(name: "can_create_post")
      permissions << Permission.find_by(name: "can_edit_own_posts")
    end
    if ["moderator", "owner"].include? self.role
      permissions << Permission.find_by(name: "can_ban_users")
    end
    if ["owner"].include? self.role
      permissions << Permission.find_by(name: "can_create_official_posts")
    end
    permissions
  end

  def has_permission?(permission, list = nil)
    p = list || self.get_permission
    return false if p.nil? or p.empty?
    p.map(&:name).include? permission
  end

  def ban(reason, end_date, post = nil)
    if self.role == "banned"
      old_role = Ban.where(user: self.user, group: self.user).where.not(group_role: "banned").order("end_date DESC").first.group_role
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
