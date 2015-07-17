$ ->
  if window.location.pathname.match(/\/account/)
    $('#new_favourite_game').click ->
      id = $('#favourite_games').children().length
      html = $.parseHTML "<input name='user[games][#{id}][name]' type='text' id='user_games_name'>"
      $('#favourite_games').append html
      return
    $('#new_skill').click ->
      # this is so dirtyyyyy
      id = $('#skills').children().length
      html = $('#skills').children()[0].outerHTML.replace(/selected=\"selected\" /g, "")
      html = html.replace(/\[(\d)\]/g, "[#{id}]").replace(/_\d_/g, "_#{id}_")
      html = html.replace /type="hidden" value="\d+"/, 'type="hidden"'
      id = html.match(/id=\"(user_skills_attributes_\d+_note)\"/)[1]
      $('#skills').append html
      $("##{id}").val("")
      return
  if window.location.pathname.match(/\/user\/([\d\w]*)/i)
    $('.edit-section .hide').click -> 
      section = $(this).data('section')
      t = this
      $.ajax
        url: '/ajax/user/hide'
        type: 'POST'
        dataType: 'text'
        data: {'section': section}
        beforeSend: (xhr) ->
          xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
        complete: (data) ->
          $(t).toggleClass('disabled')
          console.log $(".#{section}-card .hidden-section")
          $(".#{section}-card .hidden-section").toggleClass("active")
  if window.location.pathname.match(/\/search/i)
    $('#search-filter').change ->
      $('#filtered-search-form').submit()
    $('#search-bar').on 'propertychange change keyup paste input', ->
      $('#hidden-search-field').val($(this).val())
  if window.location.pathname.match(/^\/$|^\/user\/\w*\/\d*$/i)
    $('.edit-post').click ->
      # This is less terrible!
      # Why, jQuery. Why.
      t = $(this)

      global_parent = $(this).parent().parent().parent().parent()
      id = global_parent.data("id")
      default_controls = global_parent.find(".user .user-controls .default-controls")
      edit_controls = global_parent.find(".user .user-controls .edit-controls")

      cancel_post = global_parent.find(".user .user-controls .edit-controls .cancel-post")
      submit_post = global_parent.find(".user .user-controls .edit-controls .submit-post")

      post = global_parent.find(".body p")
      original_text = post.text()
      text_height = post.height()

      post.replaceWith $("<textarea class='edit-box'>#{original_text}</textarea>")
      text_area = global_parent.find("textarea")
      text_area.height text_height
      default_controls.hide()
      edit_controls.show()

      cancel_post.click ->
        text_area.replaceWith $("<p>#{original_text}</p>")
        edit_controls.hide()
        default_controls.show()

      submit_post.click ->
        text = text_area.val()
        $.ajax
          url: '/user/post/update'
          type: 'POST'
          dataType: 'json'
          data: {id: id, body: text}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            text_area.replaceWith $("<p>#{data.body}</p>")
            edit_controls.hide()
            default_controls.show()
          error: (data) ->
            console.log data.responseJSON.errors.join("\n")
            alert("An error occured editing your post:\n#{data.responseJSON.errors.join("\n")}")

    $('.delete-post').click ->
      global_parent = $(this).parent().parent().parent().parent()
      id = global_parent.data("id")
      if window.confirm "Do you really want to delete this post?"
        $.ajax
          url: '/user/post/delete'
          type: 'POST'
          dataType: 'text'
          data: {id: id}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            global_parent.height(global_parent.height())
            global_parent.toggleClass("hiding")
            global_parent.find(".user").fadeOut()
            global_parent.slideUp()
            if window.location.pathname.match(/^\/user\/\w*\/\d*$/i)
              Turbolinks.visit("/")
          error: (data) ->
            alert("An error occured deleting your post: #{data.statusText}")