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
            split_body[i] = auto_link_urls(CGI.escapeHTML(line), data: { no_turbolink: true }) {|t| truncate(t, length: 50)}
          else
            split_body[i] = CGI.escapeHTML(line)
          end
        end
        body = split_body.join("\n").html_safe
      end
      return body
    end
  end

  def ban_string(ban)
    duration_string = "for #{ban.duration_string}"
    duration_string = "until the end of time" if ban.duration_string.nil? or ban.duration_string.include? "perm"

    if ban.end_date.nil? or ban.end_date > Time.now
      "User was banned by #{display_name(ban.banner)} #{duration_string}#{": #{ban.reason}" unless ban.reason.blank?}"
    else
      "User was unbanned by #{display_name(ban.banner)}#{": #{ban.reason}" unless ban.reason.blank?}"
    end
    
  end

  def number_to_cardinal(num)
    case num
    when 0..9_999 # 537, 5379
      "#{number_with_delimiter num}"
    when 10_000..999_999 # 53.80K, 537.94K
      "#{number_with_precision(num.to_f / 1_000, precision: 2)}K"
    when 1_000_000..999_999_999 # 5.37M, 53.80M, 537.94M
      "#{number_with_precision(num.to_f / 1_000_000, precision: 2)}M"
    when 1_000_000_000..999_999_999_999 # 5.37B, 53.80B, 537.94B
      "#{number_with_precision(num.to_f / 1_000_000_000.00, precision: 2)}B"
    when 1_000_000_000_000..999_999_999_999_999 # 5.37T, 53.80T, 537.94T
      "#{number_with_precision(num.to_f / 1_000_000_000_000, precision: 2)}T"
    when 1_000_000_000_000_000..999_999_999_999_999_999 # 5.37P, 53.80P, 537.94P
      "#{number_with_precision(num.to_f / 1_000_000_000_000_000, precision: 2)}P"
    when 1_000_000_000_000_000_000..999_999_999_999_999_999_999 # 5.37E, 53.80E, 537.94E
      "#{number_with_precision(num.to_f / 1_000_000_000_000_000_000, precision: 2)}E"
    when 1_000_000_000_000_000_000_000..999_999_999_999_999_999_999_999 # 5.37Z, 53.80Z, 537.94Z
      "#{number_with_precision(num.to_f / 1_000_000_000_000_000_000_000, precision: 2)}Z"
    else # 5.37Y, 53.80Y, 537.94Y
      "#{number_with_precision(num.to_f / 1_000_000_000_000_000_000_000_000, precision: 2)}Y"
    end
  end
end
