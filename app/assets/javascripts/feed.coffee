new_posts = []
latest_id = null
get_new_posts = (feed, uid) ->
  if Foundation.utils.S("meta[name='unique']").attr('content') == uid
    if latest_id == undefined or latest_id == null
      latest_id = 0

    $.ajax
      url: "/timeline"
      type: 'GET'
      dataType: 'json'
      data: {'feed': feed, 'id': latest_id, 'direction': 'newer'}
      success: (data) ->
        if Foundation.utils.S("meta[name='unique']").attr('content') == uid
          #console.log "New post(s)."
          latest_id = data.latest_id
          new_posts = new_posts.concat(data.posts)
          update_new_posts_button()
      complete: (data) -> 
        window.setTimeout(get_new_posts, 10000, feed, uid)

update_new_posts_button = () ->
  button = Foundation.utils.S("#new-posts-button")
  Foundation.utils.S("#new-posts-button .num").text(new_posts.length)
  Foundation.utils.S("title").text("(#{new_posts.length}) #{@original_title}")
  if button.is(':hidden')
    button.slideDown(200)

update_comment_count = (postid) ->
  count = Foundation.utils.S("#comments-#{postid} .comment-contents").children().length
  counter = Foundation.utils.S("#post-#{postid}").find(".comment-count")
  classes = counter.attr('class').split(' ')
  if classes.indexOf('active') > 0
    if count <= 0
      classes.splice(classes.indexOf('active'), 1) # Remove 'active' from the list
  else if count > 0
    classes.push('active')
  
  counter.attr('class', classes.join(' '))
  counter.text(count)

reset_orbit_height   = (postid) ->
  post_div = Foundation.utils.S("#post-#{postid}")
  container = post_div.parent().parent()
  if container.attr('class').search('orbit-slides-container') > -1
    container.height(post_div.parent().height())

toggle_comments = (post, post_id, user_id) ->
  new Promise (resolve, reject) ->
    comments = Foundation.utils.S("#comments-#{post_id}")
    if post.attr("class").search("hidden-comments") > -1
      post.removeClass("hidden-comments")
      comments.slideDown ->
        comments.removeClass("hidden")
        reset_orbit_height(post_id)
      if comments.find('.comment-contents').attr('class').search('unloaded') > -1
        $.ajax
          url: "/feed/user/#{user_id}/#{post_id}/replies"
          type: 'GET'
          dataType: 'html'
          success: (data) ->
            loading_ring = Foundation.utils.S("#comments-#{post_id} .loading-ring")
            container = comments.find('.comment-contents')
            container.removeClass('unloaded')
            loading_ring.hide ->
              loading_ring.remove()
            $.when(container.html(data)).then () ->
              set_actions_for_comments(post_id)
              reset_orbit_height(post_id)
              return resolve(true)
    else
      comments.slideUp ->
        comments.addClass("hidden")
        post.addClass("hidden-comments")
        reset_orbit_height(post_id)
        return resolve(false)

wire_up_comments_for_new_posts = (post_id) ->
  if post_id
    console.log "post_id detected"
    posts_click_selector = "#post-#{post_id}.streamPost .comment-count"
    comments_submit_selector = "#comments-#{post_id}.comments .new-comment"
  else
    console.log "post_id not detected"
    posts_click_selector = '.streamPost .comment-count'
    comments_submit_selector = '.comments .new-comment'

  Foundation.utils.S(posts_click_selector).click ->
    t = Foundation.utils.S(this)
    post = t.parent().parent()

    post_id = post.data('id')
    user_id = post.find(".user").data("id")
    toggle_comments(post, post_id, user_id)

  Foundation.utils.S(comments_submit_selector).on 'submit', (e) ->
    e.preventDefault()
    form = Foundation.utils.S(this)
    if !sending and form.find('input[name=body]').val().trim().length > 0
      sending = true
      message = form.find('input[name=body]').val().trim()
      if !post_id
        post_id = form.parent().data('id')
      form.find('input[name=body]').val(message)
      $.ajax
        url: form.attr('action')
        type: 'POST'
        dataType: 'json'
        data: form.serialize()
        success: (data) ->
          form.parent().find('.comment-contents').html(data.body)
          form.find('input[name=body]').val('')
          update_comment_count(post_id)
          set_actions_for_comments(post_id)
        error: (jqXHR) ->
          alert(jqXHR.responseJSON.errors.join("\n"))
        complete: ->
          sending = false
          reset_orbit_height(post_id)

set_actions_for_comments = (postid) ->
  # Gods I need to clean this.
  Foundation.utils.S("#comments-#{postid} .comment .controls .edit-post").click ->
    t = Foundation.utils.S(this)
    comment_div = t.parent().parent().parent()
    id = comment_div.data("id")
    user_id = comment_div.find(".title").data("id")
    $.ajax
      url: "/feed/user/#{user_id}/#{id}.json"
      type: 'GET'
      dataType: 'json'
      success: (data) ->
        t.parent().addClass('hidden')
        body = comment_div.find(".body")
        body.addClass("hidden")
        body.after("<form class='edit-form'><input type='text' name='body' value='#{data.body}'></form>")
        reset_orbit_height(postid)
        Foundation.utils.S("#comment-#{id} .body-container .edit-form").on 'submit', (e) ->
          e.preventDefault()
          form = Foundation.utils.S(this)
          $.ajax
            url: "/feed/user/#{user_id}/#{id}"
            type: 'PATCH'
            dataType: 'json'
            data: form.serialize()
            beforeSend: (xhr) ->
              xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
            success: (data) ->
              form.remove()
              body.text(data.body)
              body.removeClass('hidden')
              t.parent().removeClass('hidden')
              reset_orbit_height(postid)
            error: (jqXHR) ->
               alert(jqXHR.responseJSON.errors.join("\n"))

    Foundation.utils.S("#comments-#{postid} .comment .controls .delete-post").click ->
      t = Foundation.utils.S(this)
      comment_div = t.parent().parent().parent()
      post_id = comment_div.parent().parent().data('id')
      id = comment_div.data("id")
      user_id = comment_div.find(".user").data("id")
      if window.confirm "Do you really want to delete this post?"
        $.ajax
          url: "/feed/user/#{user_id}/#{id}"
          type: 'DELETE'
          dataType: 'text'
          data: {id: id}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            comment_div.height(comment_div.height())
            comment_div.slideUp ->
              comment_div.remove()
              update_comment_count(post_id)
              reset_orbit_height(postid)
          error: (data) ->
            alert("An error occured deleting your comment: #{data.statusText}")

sending = false
$ ->
  if window.location.pathname.match(/^\/$|^\/feed\/([\w\d\/]*)$|^\/group\/((?!search)(?!members)(?!new)[\w\d]+)(\/posts\/\d+)?$/i)
    new_posts = []
    loading_messages = false
    end_of_stream = false

    Foundation.utils.S(".time-ago a").timeago()
    
    if window.location.pathname.match(/^\/$/)
      feed_type = "main"
    else if window.location.pathname.match(/^\/group\/([\w\d]*)$/)
      group_id = RegExp.$1
      feed_type = "group/#{group_id}"
    else
      regex = window.location.pathname.match(/^\/feed\/([\w\d\/]*)$/i)
      if regex == null
        feed_type = regex
      else
        feed_type = null

    if feed_type != null
      Foundation.utils.S(window).scroll ->
        # Each browser seems to treat all the elements used in this differently.
        # So, this is the only method that seems to work for all
        if @ie_browser or @ff_browser
          detected = document.documentElement.clientHeight + document.documentElement.scrollTop >= document.body.scrollHeight - 500
        else
          detected = window.innerHeight + document.body.scrollTop >= document.body.scrollHeight - 500

        if detected and !end_of_stream and !loading_messages
          loading_messages = true
          Foundation.utils.S("#loading-message").show()
          last_id = Foundation.utils.S('#feed-posts').children().last().data("id")
          if last_id == undefined or last_id == null
            last_id = 0
          $.ajax
            url: "/timeline"
            type: 'GET'
            dataType: 'json'
            data: {'feed': feed_type, 'id': last_id, 'direction': 'older'}
            success: (data) ->
              for post in data.posts
                do ->
                  Foundation.utils.S('#feed-posts').append(post)
                  Foundation.utils.S(".time-ago a").last().timeago()
              loading_messages = false
              Foundation.utils.S("#loading-message").hide()
            failure: (data) ->
              end_of_stream = true

    wire_up_comments_for_new_posts()

    # Open comments and scroll to relevant comment when using an anchor to select a comment
    if window.location.pathname.match(/^\/feed\/user\/([\w\d\/]*)\/([\d\/]*)$|^\/group\/((?!search)(?!members)(?!new)[\w\d]+)(\/posts\/\d+)$/i) and window.location.hash.startsWith("#comment-")
      post = Foundation.utils.S('.streamPost')
      post_id = post.data('id')
      user_id = post.find(".user").data("id")
      toggle_comments(post, post_id, user_id).then (f) ->
        comment = Foundation.utils.S(window.location.hash)
        comment.addClass('highlight-comment')
        comment[0].scrollIntoView(false)

    Foundation.utils.S('.streamPost .default-controls .edit-post').click ->
      # This is less terrible!
      # Why, jQuery. Why.
      t = Foundation.utils.S(this)

      this_control = $(this)

      global_parent = Foundation.utils.S(this).parent().parent().parent().parent()
      id = global_parent.data("id")
      user_id = global_parent.find(".user").data("id")
      default_controls = global_parent.find(".user .user-controls .default-controls")
      edit_controls = global_parent.find(".user .user-controls .edit-controls")
      original_text = ""

      $.ajax
        url: "/feed/user/#{user_id}/#{id}.json"
        type: 'GET'
        async: false
        dataType: 'json'
        error: (data) ->
            console.log data.responseJSON.errors.join("\n")
            alert("An error occured loading your post:\n#{data.responseJSON.errors.join("\n")}")
        success: (data) ->
          original_text = data.body

      cancel_post = global_parent.find(".user .user-controls .edit-controls .cancel-post")
      submit_post = global_parent.find(".user .user-controls .edit-controls .submit-post")

      post = global_parent.find(".body .main-section .content")
      original_html = post.html()
      text_height = post.height()

      metacard = global_parent.find(".body .main-section .metadata-card").parent()
      metacard.hide()

      post.replaceWith $("<textarea id=\"#{this_control.attr('id')}\" maxlength=\"512\" class='edit-box'>#{original_text}</textarea>")
      text_area = global_parent.find("textarea")
      text_area.height text_height
      default_controls.hide()
      edit_controls.show()

      cancel_post.click ->
        text_area.replaceWith $("<p class='content'>#{original_html}</p>")
        edit_controls.hide()
        default_controls.show()
        metacard.show()

      submit_post.click ->
        text = text_area.val()
        $.ajax
          url: "/feed/user/#{user_id}/#{id}"
          type: 'PATCH'
          dataType: 'json'
          data: {body: text}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            text_area.replaceWith $("<p class='content'>#{data.body}</p>")
            edit_controls.hide()
            default_controls.show()
            metacard.remove()
          error: (data) ->
            console.log data.responseJSON.errors.join("\n")
            alert("An error occured editing your post:\n#{data.responseJSON.errors.join("\n")}")

      $.wire_up_the_remaining_characters()

    Foundation.utils.S('.streamPost .default-controls .delete-post').click ->
      global_parent = Foundation.utils.S(this).parent().parent().parent().parent()
      id = global_parent.data("id")
      user_id = global_parent.find(".user").data("id")
      if window.confirm "Do you really want to delete this post?"
        $.ajax
          url: "/feed/user/#{user_id}/#{id}"
          type: 'DELETE'
          dataType: 'text'
          data: {id: id}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            global_parent.height(global_parent.height())
            global_parent.toggleClass("hiding")
            global_parent.find(".user").fadeOut()
            global_parent.slideUp()
            if window.location.pathname.match(/^\/user\/\w*\/\d*$/i)
              Turbolinks.visit("/")
          error: (data) ->
            alert("An error occured deleting your post: #{data.statusText}")

    Foundation.utils.S(".metadata-card[data-video] .image-container *").click (e) ->
      e.preventDefault()
      t = Foundation.utils.S(this)
      container = t.parent().parent()
      video = container.data("video")
      mime = container.data("mime")
      container.find('.image-container').addClass('hidden')
      container.prepend('<div class="video-container"></div>')
      # For youtube, autoplay.
      # Don't show controls, and loop for imgur gfy's and gfycat liks
      if video.match(/^https?:\/\/(\w+\.)?imgur.com\/(\w*\d\w*)+(\.[a-z0-9]{3,4})?$/i) or video.match(/^https?:\/\/(\w+\.)?gfycat.com\/([\w-]*)(\.[a-z0-9]{3,4})?/i)
        controls = ""
        loopc = "loop"
      else
        controls = "controls"
        loopc = ""
      if video.match(/^(https?\:\/\/)?(www\.)?youtube\.com\/embed\/(.+)$/i)
        video = "#{video}?autoplay=1"
      switch mime.toLowerCase()
        when "video"
          container.find('.video-container').prepend("<video src='#{video}' autoplay #{controls} #{loopc}></video>")
        # Should we have one for audio?
        else
          # Calculate height to 16:9 formula: Round(Width / (16 / 9))
          width = container.width()
          height = Math.round(width / (16 / 9))
          container.find('.video-container').prepend("<iframe src='#{video}' height='#{height}' frameborder='0'>")

    if window.location.pathname.match(/^\/group\/([\w\d]*)$/)
      Foundation.utils.S('.streamPost .default-controls .pin-post').click ->
        t = Foundation.utils.S(this)
        global_parent = t.parent().parent().parent().parent()
        id = global_parent.data("id")
        
        $.ajax
          url: "/group/#{group_id}/posts/#{id}/pin"
          type: 'POST'
          dataType: 'text'
          data: {id: id}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            # what a mess...
            # TODO: Copy comments section with post as well.
            # Loop through every post of that id on the page (there should be either 1 or 2)
            # after successfully toggling on the serverside if the post is:
            # Pinned:
              # Find the pinned post in the stickied list and remove it
              # And all it's elements in the orbit container
              # As well as re-numbering the remanining elements in the orbit
            # Unpinned:
              # Copy the post to the front of the orbit container and add an orbit-nav button for it
              # Ensure the copied post has the appropriate "stick" class on it
              # Ensure the post is cloned so that any events are still valid on it
              # Renumber the elements in the orbit container
              # Reset the height for orbit to ensure it's matched with the new post
              # Reset foundation orbit to ensure it catches up

            sticked = false
            for post in Foundation.utils.S(".streamPost[data-id='#{id}']")
              do ->
                post = Foundation.utils.S(post)
                post.find('.pin-post').toggleClass("active")
                if post.hasClass("stick")
                  sticked = true
                  # Remove the pinned post and renumber the orbit elements
                  post.parent().remove()
                  i = 0
                  for elm in Foundation.utils.S(".orbit-slides-container").children()
                    do ->
                      Foundation.utils.S(elm).attr("data-orbit-slide", "stickied-#{i}")
                      i++
                  # Remove the last orbit-nav button
                  Foundation.utils.S("#stickied-button-#{i}").remove()
                  # Reset orbit height and foundation
                  reset_orbit_height(Foundation.utils.S('.orbit-slides-container').children().first().children().first().data('id'))
                  $(document).foundation('orbit', 'reflow');
                else if sticked != true
                  # Create a li container for the post  in the orbit container
                  Foundation.utils.S('.orbit-slides-container').prepend('<li></li>')
                  # Clone the post and add the stick class to it, and append to the new li
                  post.clone(true, true).toggleClass("stick").appendTo(Foundation.utils.S('.orbit-slides-container').children().first())
                  # Add a new orbit nav button
                  nav_size = Foundation.utils.S('.orbit-nav').children().size()
                  Foundation.utils.S('.orbit-nav').append("<a data-orbit-link='stickied-#{nav_size}' id='stickied-button-#{nav_size}'></a>")
                  # Renumber the slides
                  i = 0
                  for elm in Foundation.utils.S(".orbit-slides-container").children()
                    do ->
                      Foundation.utils.S(elm).attr("data-orbit-slide", "stickied-#{i}")
                      i++
                  # Reset height and reset foundation
                  reset_orbit_height(Foundation.utils.S('.orbit-slides-container').children().first().children().first().data('id'))
                  $(document).foundation('orbit', 'reflow');
          error: (data) ->
            alert("An error occured pinning the comment: #{data.statusText}")

    if feed_type != null
      latest_id = Foundation.utils.S('#feed-posts').children().first().data("id")
      get_new_posts(feed_type, Foundation.utils.S("meta[name='unique']").attr('content'))

    Foundation.utils.S('#new-posts-button').click ->
      Foundation.utils.S(this).hide()
      Foundation.utils.S('title').text(original_title)
      posts = new_posts
      new_posts = []
      for post in posts # Why does the 'do' have to be a on a newline? wtf coffeescript?
        do ->
          Foundation.utils.S('#feed-posts').prepend(post)
          latest_post = Foundation.utils.S('.streamPost').sort((a, b) ->
            Foundation.utils.S(b).data('id') - Foundation.utils.S(a).data('id')
          ).first()
          latest_post.find('.time-ago a').timeago()
          wire_up_comments_for_new_posts(latest_post.data('id'))

