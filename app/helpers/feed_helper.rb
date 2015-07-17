module FeedHelper
  def post_time_ago(post)
    text = "#{link_to time_ago_in_words(post.created_at) + " ago", "/user/#{post.user.username}/#{post.id}"}"
    text << "<span data-tooltip aria-haspopup=\"true\" title=\"Edited #{time_ago_in_words(post.updated_at)} ago\">*</span>" if post.created_at != post.updated_at
    return text.html_safe
  end
end
