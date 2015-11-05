class User < ActiveRecord::Base
  include Postable
  include PgSearch
  multisearchable against: [:username, :display_name]

  enum skill_status: [:empty, :looking_for_group, :looking_for_more]

  has_attached_file :avatar,
                  path: "users/avatars/:style/:id.:extension",
                  styles: {
                    thumb: '64x64>',
                    med:   '150x150#',
                    large: '256x256#'
                  }

  attr_accessor :old_password, :email_confirm, :skip_old_password
  has_and_belongs_to_many :games
  belongs_to :role
  has_many :skills, -> { order 'confidence DESC' }, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :posts, -> { order 'created_at ASC' }, dependent: :destroy
  has_many :bans, -> { order 'id DESC'}, dependent: :destroy
  has_many :follows, dependent: :destroy
  has_many :followers, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy
  has_many :group_memberships
  has_many :groups, through: :group_memberships

  validates :username, :display_name, length: { maximum: 25 }
  validates_format_of :username, with: /\A([a-zA-Z](_?[a-zA-Z0-9]+)*_?|_([a-zA-Z0-9]+_?)*)\z/ # Twitter username rules.
  validates :bio, length: { maximum: 512 }
  validates :decrypted_email, length: {maximum: 325}, on: :create # A bit over what should be the maximum, just incase.
  validates :hashed_email, uniqueness: true
  validates :username, uniqueness: {case_sensitive: false}
  validates :verification_digest, uniqueness: true, allow_blank: true, allow_nil: true
  validates :display_name, uniqueness: true, case_sensitive: false, allow_blank: true, allow_nil: true
  validates :username, :password_digest, :email, presence: true
  validates_format_of :decrypted_email, with: /\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i, on: :create
  validates_attachment :avatar, content_type: { content_type: ['image/jpeg', 'image/png', 'image/bmp'] },
                       attachment_size: { less_than: 512.kilobytes }
  validates :skill_notes, length: {maximum: 256}
  validate :validates_old_password, unless: :skip_old_password
  validate :validates_email_equality, on: :create

  before_validation :hash_email
  before_create :encrypt_email
  before_create :set_default_role

  accepts_nested_attributes_for :skills, allow_destroy: true
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_secure_password

  before_validation do
    remove_zalgo! self.display_name
    remove_zalgo! self.bio
    self.enc_key = self.enc_key || SecureRandom.hex(64)
  end

  def hash_email
    # I feel like we should do more than just a SHA-2 of Email... hrm.
    self.hashed_email = Digest::SHA384.hexdigest(self.decrypted_email.downcase + ENV['EMAIL_SALT'])
  end
  
  # Email storage crypto
  def encrypt_email
    crypt = OpenSSL::Cipher::AES256.new(:CBC)
    crypt.encrypt
    crypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + self.enc_key)
    iv = self.email_iv || crypt.random_iv
    crypt.iv = iv
    self.email_iv = iv
    self.email = crypt.update(self.decrypted_email) + crypt.final
  end

  def decrypted_email
    begin
      crypt = OpenSSL::Cipher::AES256.new(:CBC)
      crypt.decrypt
      crypt.key = Digest::SHA2.hexdigest(ENV['EMAIL_KEY'] + self.enc_key)
      crypt.iv = self.email_iv
      crypt.update(self.email) + crypt.final
    rescue # I should have specific cases here but it'll be a lot...
      self.email
    end
  end

  def set_default_role
    self.role = Role.find_by(name: "default") if self.role.nil?
  end

  def generate_verification_digest
    if self.verification_active.nil? or self.verification_active < Time.now
      self.verification_digest = SecureRandom.urlsafe_base64
      self.verification_active = 24.hours.from_now
      self.save
    end
  end

  # Why is this a function
  def generate_password_reset_link
    "http://leagueforgamers.com/user/forgot_password/#{self.verification_digest}"
  end

  def has_permission?(permission)
    return false if self.role.nil?
    self.role.permissions.map(&:name).include? permission
  end

  def ban(reason, end_date, post = nil)
    banned_role = Role.find_by(name: "banned")
    if self.role.name == "banned"
      old_role = Ban.where(user: self).where.not(role: banned_role).order("end_date DESC").first.role
    else
      old_role = self.role
    end
    ban = Ban.new(user: self, reason: reason, end_date: end_date, role: old_role)
    ban.post = post unless post.nil?
    ban.save
    self.role = banned_role
    self.save
  end

  # Usage: user_that_current_user_wants_to_follow.follow(current_user)
  def follow(user)
    Follow.create(user: user, following: self)
  end

  private
    # THANKS STACK OVERFLOW! http://stackoverflow.com/questions/12663593/has-secure-password-authenticate-inside-validation-on-password-update
    def validates_old_password
      return if password_digest_was.nil? || !password_digest_changed?
      errors.add(:old_password, "is incorrect") unless BCrypt::Password.new(password_digest_was) == old_password
    end

    def validates_email_equality
      errors.add(:email, "does not match") unless decrypted_email == email_confirm
    end
end
