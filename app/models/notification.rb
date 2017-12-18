class Notification < ApplicationRecord
  belongs_to :group, required: false
  belongs_to :post, required: false
  belongs_to :user

  validates_presence_of :variant

  scope :unread, lambda { where(read: false) }

  after_create :delete_older_messages

  enum variant: [:group_invite, # Sent to group admins when a user requests invitation
    :group_invited, # Sent to user when they've been invited to a group
    :group_accepted, # Sent to a user when their invitation has been acccepted
    :group_ban, # Sent to a user when they've been banned from a group
    :group_unban, # Sent to a user when they've been unbanned from a group
    :ban, # Sent to a user upon global ban
    :unban, # Sent to a user upon global unban
    :mention, # Sent to a user when their name is mentioned
    :new_comment] # Sent to a user when someone has commented on their post

  MAX_NOTIFICATION_COUNT = 30

  # TODO: Job that coalesces multiple comments on one post into one notification

  private
    def delete_older_messages
      to_delete = Notification.where(user: @current_user, read: true).order("created_at DESC").offset(MAX_NOTIFICATION_COUNT)
      to_delete.each(&:destroy)
    end
end
