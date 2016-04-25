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

    Foundation.utils.S('.edit-post').click ->
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

    Foundation.utils.S('.sign_text').click ->
      form = $(this).parent()
      body_field = form.find('#body')
      signature_field = form.find('#signed')
      LFGCrypto.get_private_key().then (key) ->
        LFGCrypto.sign_message(body_field.val(), key).then (signed) ->
          signature_field.val(signed)

    for p in Foundation.utils.S('p[data-signed]')
      p = Foundation.utils.S(p)
      post = p.parent().parent()
      username = post.find('.user').data('id')
      id = post.data('id')
      signature = p.data('signed')
      message = p.text()
      LFGCrypto.get_public_key(username).then (key) ->
        LFGCrypto.verify_signature(message, signature, key).then((result) ->
          console.log "Post #{id} passed!"
        ).catch (result) ->
          console.log "Post #{id} failed!"
      
