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

reset_orbit_height_for_comments = (postid) ->
  post_div = Foundation.utils.S("#post-#{postid}")
  container = post_div.parent().parent()
  if container.attr('class').includes('orbit-slides-container')
    container.height(post_div.parent().height())

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
        reset_orbit_height_for_comments(postid)
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
              reset_orbit_height_for_comments(postid)

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
              reset_orbit_height_for_comments(postid)
          error: (data) ->
            alert("An error occured deleting your comment: #{data.statusText}")

$ ->
  if window.location.pathname.match(/^\/$|^\/feed\/([\w\d\/]*)$|^\/group\/((?!search)(?!members)(?!new)[\w\d]+)(\/posts\/\d+)?$/i)
    new_posts = []
    loading_messages = false
    end_of_stream = false

    Foundation.utils.S(".time-ago a").timeago()
    
    if window.location.pathname.match(/^\/$/)
      feed_type = "main"
    else if window.location.pathname.match(/^\/group\/([\w\d]*)$/)
      feed_type = "group/#{RegExp.$1}"
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

    Foundation.utils.S('.streamPost .comment-count').click ->
      t = Foundation.utils.S(this)
      post = t.parent().parent()
      post_id = post.data('id')
      user_id = post.find(".user").data("id")
      comments = Foundation.utils.S("#comments-#{post_id}")
      if post.attr("class").includes("hidden-comments")
        post.removeClass("hidden-comments")
        comments.slideDown ->
          comments.removeClass("hidden")
          reset_orbit_height_for_comments(post_id)
        if comments.find('.comment-contents').attr('class').includes('unloaded')
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
              container.html(data)
              set_actions_for_comments(post_id)
              reset_orbit_height_for_comments(post_id)
      else
        comments.slideUp ->
          comments.addClass("hidden")
          post.addClass("hidden-comments")
          reset_orbit_height_for_comments(post_id)

    sending = false
    Foundation.utils.S('.comments .new-comment').on 'submit', (e) ->
      e.preventDefault()
      form = Foundation.utils.S(this)
      if !sending and form.find('input[name=body]').val().trim().length > 0
        sending = true
        message = form.find('input[name=body]').val().trim()
        post_id = form.parent().data('id')
        form.find('input[name=body]').val(message)
        $.ajax
          url: form.attr('action')
          type: 'POST'
          dataType: 'json'
          data: form.serialize()
          success: (data) ->
            form.parent().find('.comment-contents').html(data.body)
          complete: ->
            form.find('input[name=body]').val('')
            sending = false
            update_comment_count(post_id)
            set_actions_for_comments(post_id)
            reset_orbit_height_for_comments(post_id)

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

      post = global_parent.find(".body p")
      original_html = post.html()
      text_height = post.height()

      post.replaceWith $("<textarea id=\"#{this_control.attr('id')}\" maxlength=\"512\" class='edit-box'>#{original_text}</textarea>")
      text_area = global_parent.find("textarea")
      text_area.height text_height
      default_controls.hide()
      edit_controls.show()

      cancel_post.click ->
        text_area.replaceWith $("<p>#{original_html}</p>")
        edit_controls.hide()
        default_controls.show()

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
            text_area.replaceWith $("<p>#{data.body}</p>")
            edit_controls.hide()
            default_controls.show()
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
          Foundation.utils.S('.streamPost').sort((a, b) ->
            Foundation.utils.S(b).data('id') - Foundation.utils.S(a).data('id')
          ).first().find('.time-ago a').timeago()
