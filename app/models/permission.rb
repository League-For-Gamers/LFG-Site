class Permission < ActiveRecord::Base
  validates :name, presence: true
end
