module GroupHelper
  def group_post_time_ago(post)
    text = "#{link_to post.created_at.iso8601, "/group/#{post.group.slug}/posts/#{post.id}", title: post.created_at.iso8601}"
    text << "<span data-tooltip aria-haspopup=\"true\" title=\"Last edited at #{post.updated_at}\">*</span>" if post.created_at != post.updated_at
    text = "<span class='time-ago'>#{text}</span>"
    return text.html_safe
  end
end
