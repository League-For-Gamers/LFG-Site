module ApplicationHelper
  def logged_in?
    !!session[:user]
  end

  def display_name(user)
    user.display_name || "@#{user.username}"
  end

  def full_urlify(url)
    url = "http://#{url}" unless url =~ /\Ahttp[s]?:\/\//i
    url
  end

  def reverse_urlify(url)
    url.gsub(/\Ahttp[s]?:\/\//i, '')
  end

  # I feel like this could be so much simpler...
  def replace_urls(body)
    unless body.blank?
      urls = URI.extract(body, ["http", "https"])
      unless urls.empty?
        split_body = body.split("\n")
        split_body.each_with_index do |line, i| # Map didn't want to work here :(
          if line =~ URI::regexp(["https", "http"])
            split_body[i] = auto_link_urls(CGI.escapeHTML(line)) {|t| truncate(t, length: 50)}
          else
            split_body[i] = CGI.escapeHTML(line)
          end
        end
        body = split_body.join("\n").html_safe
      end
      return body
    end
  end
end
