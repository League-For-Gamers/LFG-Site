class MarkNotificationsAsReadJob < ActiveJob::Base
  queue_as :default

  def perform(notifications)
    notifications.each do |n|
      n.toggle!(:acknowledged) unless n.acknowledged?
    end
  end
end
