class User < ActiveRecord::Base
  include Postable
  include PgSearch
  multisearchable against: [:username, :display_name]

  enum skill_status: [:empty, :looking_for_group, :looking_for_more]

  attr_accessor :old_password, :email_confirm
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :games
  has_many :skills, -> { order 'confidence DESC' }, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :posts, -> { order 'created_at ASC' }, dependent: :destroy

  validates :username, :display_name, length: { maximum: 25 }
  validates_format_of :username, with: /\A([a-zA-Z](_?[a-zA-Z0-9]+)*_?|_([a-zA-Z0-9]+_?)*)\z/ # Twitter username rules.
  validates :bio, length: { maximum: 512 }
  validates :decrypted_email, length: {maximum: 325}, on: :create # A bit over what should be the maximum, just incase.
  validates :hashed_email, uniqueness: true
  validates :username, uniqueness: true
  validates :display_name, uniqueness: true, case_sensitive: false, allow_blank: true, allow_nil: true
  validates :username, :password_digest, :email, presence: true
  validates_format_of :decrypted_email, with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, on: :create
  validates :avatar, attachment_content_type: { content_type: /\Aimage\/.*\Z/ },
                     attachment_size: { less_than: 512.kilobytes }
  validates :skill_notes, length: {maximum: 256}
  validate :validates_old_password
  validate :validates_email_equality, on: :create

  accepts_nested_attributes_for :skills, allow_destroy: true
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_secure_password

  has_attached_file :avatar,
                    path: "users/avatars/:style/:id.:extension",
                    styles: {
                      thumb: '64x64>',
                      med:   '150x150#',
                      large: '256x256#'
                    }

  before_validation do
    remove_zalgo! self.display_name
    remove_zalgo! self.bio

    # I feel like we should do more than just a SHA-2 of Email... hrm.
    self.hashed_email = Digest::SHA384.hexdigest(self.decrypted_email + ENV['EMAIL_SALT'])
  end
  
  # Email storage crypto
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

  private
    # THANKS STACK OVERFLOW! http://stackoverflow.com/questions/12663593/has-secure-password-authenticate-inside-validation-on-password-update
    def validates_old_password
      return if password_digest_was.nil? || !password_digest_changed?
      unless BCrypt::Password.new(password_digest_was) == old_password
        errors.add(:old_password, "is incorrect")
      end
    end

    def validates_email_equality
      unless decrypted_email == email_confirm
        errors.add(:email, "does not match")
      end
    end
end
