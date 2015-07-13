# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  def recovery_email
    user = User.first
    user.generate_verification_digest
    UserMailer.recovery_email(user)
  end
end
