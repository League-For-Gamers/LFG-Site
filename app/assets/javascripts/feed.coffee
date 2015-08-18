get_new_posts = (feed, url) ->
  if window.location.pathname == url
    latest_id = Foundation.utils.S('#feed-posts').children().first().data("id")
    $.ajax
      url: "/timeline"
      type: 'GET'
      dataType: 'html'
      data: {'feed': feed, 'id': latest_id, 'direction': 'newer'}
      complete: (data) ->
        Foundation.utils.S('#feed-posts').prepend(data.responseText)
        window.setTimeout(get_new_posts, 10000, feed, url)

$ ->
  if window.location.pathname.match(/^\/$|^\/feed\/([\w\d\/]*)$/i)
    loading_messages = false
    end_of_stream = false
    
    if window.location.pathname.match(/^\/$/)
      feed_type = "main"
    else
      feed_type = window.location.pathname.match(/^\/feed\/([\w\d\/]*)$/i)[1]

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
        $.ajax
          url: "/timeline"
          type: 'GET'
          dataType: 'html'
          data: {'feed': feed_type, 'id': last_id, 'direction': 'older'}
          complete: (data) ->
            if data.responseText.length == 0
              end_of_stream = true
            Foundation.utils.S('#feed-posts').append(data.responseText)
            loading_messages = false
            Foundation.utils.S("#loading-message").hide()

    Foundation.utils.S('.edit-post').click ->
      # This is less terrible!
      # Why, jQuery. Why.
      t = Foundation.utils.S(this)

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

      post.replaceWith $("<textarea class='edit-box'>#{original_text}</textarea>")
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

    Foundation.utils.S('.delete-post').click ->
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

    get_new_posts(feed_type, window.location.pathname)