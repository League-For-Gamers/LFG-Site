class User < ActiveRecord::Base
  include Postable
  include PgSearch
  multisearchable against: [:username, :display_name]

  enum skill_status: [:empty, :looking_for_group, :looking_for_more]

  has_attached_file :avatar,
                  processors: [:thumbnail, :paperclip_optimizer],
                  paperclip_optimizer: {
                    optipng: { level: 6 }
                  },
                  path: "users/avatars/:style/:id.:extension",
                  styles: {
                    thumb: { geometry: '64x64>' },
                    med:   { geometry: '150x150#' },
                    large: { geometry: '256x256#' }
                  }

  attr_accessor :old_password, :email_confirm, :skip_old_password
  has_and_belongs_to_many :games
  belongs_to :role
  has_many :skills, -> { order 'confidence DESC' }, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :posts, -> { order 'created_at ASC' }, dependent: :destroy
  has_many :bans, -> { order 'id DESC'}, dependent: :destroy
  has_many :own_bans, -> { order 'id DESC'}, class_name: 'Ban', foreign_key: 'banner_id'
  has_many :follows, dependent: :destroy
  has_many :followers, class_name: 'Follow', foreign_key: 'following_id', dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :notifications, dependent: :destroy

  validates :username, :display_name, length: { maximum: 25 }
  validates_format_of :username, with: /\A([a-zA-Z0-9_](_?[a-zA-Z0-9]+)*_?|_([a-zA-Z0-9]+_?)*)\z/ # Twitter username rules.
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
  after_create :join_lfg_group

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

  def ban(reason, end_date, banner, post = nil)
    banned_role = Role.find_by(name: "banned")
    if self.role.name == "banned"
      old_role = Ban.where(user: self).where.not(role: banned_role).order("created_at DESC").first.role
    else
      old_role = self.role
    end

    duration_string = ActionView::Base.new.distance_of_time_in_words Time.now, end_date unless end_date.nil?
    duration_string = "permanently" if end_date.nil?

    ban = Ban.new(user: self, reason: reason, end_date: end_date, role: old_role, banner: banner, duration_string: duration_string)
    ban.post = post unless post.nil?
    if ban.valid?
      ban.save  
      self.role = banned_role
      self.save
      notification_message = "for #{ban.duration_string}"
      notification_message = 'until the end of time' if end_date.nil?
      notification_message = "by #{banner.display_name || banner.username}"
      notification_message << ": #{reason}" unless reason.blank?
      self.create_notification("ban", nil, notification_message)
    else
      raise ban.errors.full_messages.join(", ")
    end
  end

  # Usage: current_user.follow(user_that_current_user_wants_to_follow)
  def follow(user)
    Follow.create(user: self, following: user)
  end

  def create_notification(variant, group = nil, message = nil)
    Notification.create(variant: Notification.variants[variant], user: self, group: group, message: message)
  end

  def follow?(user)
    self.follows.map(&:following_id).include? user.id
  end

  private
    def join_lfg_group
      g = Group.find_by(slug: "league_for_gamers")
      GroupMembership.create(user: self, group: g, role: :member)
    end

    # THANKS STACK OVERFLOW! http://stackoverflow.com/questions/12663593/has-secure-password-authenticate-inside-validation-on-password-update
    def validates_old_password
      return if password_digest_was.nil? || !password_digest_changed?
      errors.add(:old_password, "is incorrect") unless BCrypt::Password.new(password_digest_was) == old_password
    end

    def validates_email_equality
      errors.add(:email, "does not match") unless decrypted_email == email_confirm
    end
end
