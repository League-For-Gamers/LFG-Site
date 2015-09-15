$ ->
  $('textarea[maxlength]').each (_, item) ->
    item = $(item)
    text_max = parseInt item.attr('maxlength')
    if $("##{item.attr('id')}_feedback").length == 1
      feedback = ->
        text_length = item.val().length
        text_remaining = text_max - text_length
        $("##{item.attr('id')}_feedback").html text_remaining
      item.keyup feedback
      feedback()

  if window.location.pathname.match(/^\/$|^\/feed\/([\w\d\/]*)$/i)
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
