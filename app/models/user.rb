class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :games
  has_many :skills

  validates :username, :display_name, length: { maximum: 16 }
  validates :username, :display_name, uniqueness: true, :case_sensitive => false
  validates :username, :password_digest, presence: true

  has_secure_password
end
