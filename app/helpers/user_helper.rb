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
      "https://www.youtube.com/user/#{social[1]}"
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
    if post.created_at != post.updated_at
      "Edited about #{time_ago_in_words(post.updated_at)} ago<span title=\"#{"Created about #{time_ago_in_words(post.created_at)} ago"}\">*</span>".html_safe
    else
      "#{time_ago_in_words(post.created_at)} ago"
    end
  end
end
