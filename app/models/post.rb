class Post < ActiveRecord::Base
  include Postable
  belongs_to :user

  validates :body, length: { maximum: 512 }
  validates :user, :body, presence: true

  before_validation do
    remove_zalgo! self.body
  end
end
