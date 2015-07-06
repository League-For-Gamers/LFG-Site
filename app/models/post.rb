class Post < ActiveRecord::Base
  belongs_to :user

  validates :body, length: { maximum: 512 }
end
