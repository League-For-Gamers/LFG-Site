class UserMailer < ApplicationMailer
  def recovery_email(user)
    @user = user
    @recovery_link = user.generate_password_reset_link
    @time = Time.now
    mail to: @user.decrypted_email, subject: "League for Gamers password recovery"
  end
end
