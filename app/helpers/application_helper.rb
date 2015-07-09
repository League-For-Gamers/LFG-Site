module ApplicationHelper
  def logged_in?
    !!session[:user]
  end

  def display_name(user)
    user.display_name || "@#{user.username.titleize.tr(' ', '_')}"
  end
end
