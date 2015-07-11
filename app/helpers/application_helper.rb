module ApplicationHelper
  def logged_in?
    !!session[:user]
  end

  def display_name(user)
    user.display_name || "@#{user.username.titleize.tr(' ', '_')}"
  end

  def full_urlify(url)
    url = "http://#{url}" unless url =~ /\Ahttp[s]?:\/\//i
    url
  end

  def reverse_urlify(url)
    url.gsub(/\Ahttp[s]?:\/\//i, '')
  end
end
