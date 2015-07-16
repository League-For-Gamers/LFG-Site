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
      "https://www.linkedin.com/in/#{social[1]}"
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
end
