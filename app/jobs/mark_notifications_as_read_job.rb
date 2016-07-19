class MarkNotificationsAsReadJob < ActiveJob::Base
  queue_as :default

  def perform(notifications)
    notifications.each do |n|
      n.toggle!(:read) unless n.read?
    end
  end
end
