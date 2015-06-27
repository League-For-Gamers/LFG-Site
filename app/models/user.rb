class User < ActiveRecord::Base
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :games
  has_many :skills
  has_many :tags

  validates :username, :display_name, length: { maximum: 16 }
  validates :bio, length: { maximum: 512 }
  validates :decrypted_email, length: {maximum: 325} # A bit over what should be the maximum, just incase.
  validates :username, :display_name, uniqueness: true, :case_sensitive => false
  validates :username, :password_digest, :email, presence: true
  validates_format_of :decrypted_email, :with => /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i

  has_secure_password
  
  before_save do
    crypt = OpenSSL::Cipher::AES256.new(:CBC)
    crypt.encrypt
    crypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + self.username)
    iv = crypt.random_iv
    crypt.iv = iv
    self.email_iv = iv
    self.email = crypt.update(self.email) + crypt.final
  end

  def decrypted_email
    begin
      crypt = OpenSSL::Cipher::AES256.new(:CBC)
      crypt.decrypt
      crypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + self.username)
      crypt.iv = self.email_iv
      crypt.update(self.email) + crypt.final
    rescue # I should have specific cases here but it'll be a lot...
      self.email
    end
  end
end
