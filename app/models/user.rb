class User < ActiveRecord::Base
  include PgSearch
  multisearchable against: [:username, :display_name]

  attr_accessor :old_password
  has_and_belongs_to_many :roles
  has_and_belongs_to_many :games
  has_many :skills, dependent: :destroy
  has_many :tags, dependent: :destroy
  has_many :posts, -> { order 'created_at ASC' }, dependent: :destroy

  validates :username, :display_name, length: { maximum: 15 }
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
  validate :validates_old_password

  accepts_nested_attributes_for :skills, allow_destroy: true
  accepts_nested_attributes_for :tags, allow_destroy: true

  has_secure_password

  has_attached_file :avatar,
                    path: "users/avatars/:style/:id.:extension",
                    styles: {
                      thumb: '64x64>',
                      med:   '256x256#',
                      large: '512x512>'
                    }

  # Remove Zalgo from display names.
  # It's not perfect, but it should do just fine, it's threshold based 
  # So it shouldn't catch smaller fancy-text things.
  before_validation do
    self.display_name = self.display_name.gsub(/[\u0300-\u036f\u0489]/, '') if self.display_name =~ /[\u0300-\u036f\u0489]{3}/
  end

  before_validation do
    sha = Digest::SHA384.new
    sha.update self.decrypted_email + ENV['EMAIL_SALT']
    self.hashed_email = sha.hexdigest
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
end
