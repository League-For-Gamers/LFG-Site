module UserHelper
  def expand_social_link(social)
    case social[0]
    when "link_twitter"
      "https://twitter.com/#{social[1]}"
    when "link_facebook"
      "https://www.facebook.com/#{social[1]}"
    when "link_googleplus"
      "https://plus.google.com/#{social[1]}"
    when "link_linkedin"
      "https://www.linkedin.com/profile/view?id=#{social[1]}"
    when "link_youtube"
      "https://www.youtube.com/channel/#{social[1]}"
    when "link_instagram"
      "https://instagram.com/#{social[1]}"
    else
      social[1]
    end
  end

  def to_b(b)
    b == "true"
  end

  def post_time_ago(post)
    text = "#{link_to time_ago_in_words(post.created_at) + " ago", "/user/#{post.user.username}/#{post.id}"}"
    text << "<span data-tooltip aria-haspopup=\"true\" title=\"Edited #{time_ago_in_words(post.updated_at)} ago\">*</span>" if post.created_at != post.updated_at
    return text.html_safe
  end

  # I feel like this could be so much simpler...
  def replace_urls(body)
    urls = URI.extract(body, ["http", "https"])
    unless urls.empty?
      split_body = body.split("\n")
      split_body.each_with_index do |line, i| # Map didn't want to work here :(
        split_body[i] = auto_link_urls(CGI.escapeHTML(line)) {|t| truncate(t, length: 50)} if line =~ URI::regexp(["https", "http"])
      end
      body = split_body.join("\n").html_safe
    end
    return body
  end
end
