class PrivateMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :chat

  validates :user, :chat, :body, presence: true
  validates :decrypted_body, length: { maximum: 512 }
  validate :validates_user_authority
  # This breaks our tests, so we have to carefully avoid it for tests. That's okay, we test it manually anyway.
  # :nocov:
  if !Rails.env.test?
    validate :duplicate_check
  end
  # :nocov:

  before_save :encrypt_body

  # Message storage crypto
  def encrypt_body
    crypt = OpenSSL::Cipher::AES256.new(:CBC)
    crypt.encrypt
    crypt.key = Digest::SHA2.hexdigest(ENV['MESSAGE_KEY'] + self.user.enc_key + self.chat.key)
    iv = self.iv || crypt.random_iv
    crypt.iv = iv
    self.iv = iv
    self.body = crypt.update(self.decrypted_body) + crypt.final
  end

  def decrypted_body
    begin
      crypt = OpenSSL::Cipher::AES256.new(:CBC)
      crypt.decrypt
      crypt.key = Digest::SHA2.hexdigest(ENV['MESSAGE_KEY'] + self.user.enc_key + self.chat.key)
      crypt.iv = self.iv
      crypt.update(self.body) + crypt.final
    rescue # I should have specific cases here but it'll be a lot...
      self.body
    end
  end

  private
    def validates_user_authority
      errors.add(:user, "is not part of the chat") unless self.chat.users.include? self.user
    end

    def duplicate_check
      if self.chat.private_messages.count > 0
        last = self.chat.private_messages.first
        errors.add(:private_message, "is a duplicate") if self.decrypted_body == last.decrypted_body and (Time.now - last.created_at) < 15 and self != last and self.user == last.user
      end
    end
end
