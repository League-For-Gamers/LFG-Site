class Chat < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_many :private_messages, -> { order 'id DESC'}, dependent: :destroy

  before_validation do
    self.key = self.key || SecureRandom.hex(64)
  end
end
