module GroupHelper
  def group_post_time_ago(post, group)
    text = "#{link_to post.created_at.iso8601, "/group/#{group.slug}/posts/#{post.id}", title: post.created_at.iso8601}"
    text << "<span data-tooltip aria-haspopup=\"true\" title=\"Last edited at #{post.updated_at}\">*</span>" if post.created_at != post.updated_at
    text = "<span class='time-ago'>#{text}</span>"
    return text.html_safe
  end


  def universal_permission_check(permission, options = {})
    permissions = options[:permissions] || @permissions
    user = options[:user] || @current_user
    !!user and (GroupMembership.has_permission? permission, permissions or user.has_permission? permission)
  end
end
