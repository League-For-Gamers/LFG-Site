class Notification < ActiveRecord::Base
  belongs_to :group
  belongs_to :user

  # TODO: Delete after 30 un-acknowledged notifications.

  after_initialize :default_values

  enum variant: [:group_invite, :group_invited, :group_accepted, :group_ban, :group_unban, :ban, :unban, :mention]

  def resolve_url
    case self.variant
    when "group_invite"
      "/group/#{self.group.slug}/members"
    when "group_invited"
      "/group/#{self.group.slug}/accept"
    when "group_accepted"
      "/group/#{self.group.slug}"
    when "group_ban", "group_unban"
      "/group/#{self.group.slug}"
    when "ban", "unban"
      "/"
    when "mention"
    end
  end

  def resolve_message
    case self.variant
    # Sent to admins and owners of group when a user requests the join
    when "group_invite"
      "The user #{self.message} has requested to join your group #{self.group.title}" # Message is requestee display_name

    # Sent to user when they're invited to join a group
    when "group_invited"
      "You have been invited to join the group #{self.group.title} by #{self.message}"

    # Sent to user who requested to join when accepted
    when "group_accepted"
      "You have been accepted into the group #{self.group.title}"

    # Sent to banned user when banned from group
    when "group_ban"
      "You have been banned from the group #{self.group.title} #{self.message}" # Message eg: "for 24 days by admin: 'wanker'"

    # Send to unbanned user when explicitly unbanned (not when ban is lapsed) from group
    when "group_unban"
      "You have been unbanned from the group #{self.group.title} #{self.message}" # Message eg: "by admin: not a massive wanker"

    # Sent to banned user
    when "ban"
      "You have been banned from the site #{self.message}" # Message same as group_ban

    # Sent to user when explicitly unbanned (not when ban is lapsted)
    when "unban"
      "You have been unbanned from the site #{self.message}" # Message same as group_unban

    # Sent to user when mentioned. Not currently implemented.
    when "mention"
    end
  end

  private
    def default_values
      self.acknowledged ||= false
    end
end
