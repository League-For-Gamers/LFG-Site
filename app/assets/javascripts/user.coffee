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
      id = html.match(/id=\"(user_skills_attributes_\d_note)\"/)[1]
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
      # This is fucking terrible.
      id = $(this).data("id")
      edit_post = $(this)
      cancel_post = $("#post-#{id} .cancel-post")
      submit_post = $("#post-#{id} .submit-post")
      edit_controls = $("#post-#{id} .edit-controls")
      original_text = $("#post-#{id} p").text()
      text_height = $("#post-#{id} p").height()
      $("#post-#{id} p").replaceWith $("<textarea class='edit-box'>#{$("#post-#{id} p").text()}</textarea>")
      $("#post-#{id} textarea").height text_height
      edit_post.hide()
      edit_controls.toggleClass("show")
      cancel_post.click ->
        id = $(this).data("id")
        $("#post-#{id} textarea").replaceWith $("<p>#{original_text}</p>")
        edit_controls.toggleClass("show")
        edit_post.show()
      submit_post.click ->
        id = $(this).data("id")
        text = $("#post-#{id} textarea").val()
        $.ajax
          url: '/user/post/update'
          type: 'POST'
          dataType: 'json'
          data: {id: id, body: text}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            $("#post-#{id} textarea").replaceWith $("<p>#{data.body}</p>")
            edit_controls.toggleClass("show")
            edit_post.show()
          error: (data) ->
            console.log data.responseJSON.errors.join("\n")
            alert("An error occured editing your post:\n#{data.responseJSON.errors.join("\n")}")

    $('.delete-post').click ->
      id = $(this).data("id")
      t = this
      if window.confirm "Do you really want to delete this post?"
        $.ajax
          url: '/user/post/delete'
          type: 'POST'
          dataType: 'text'
          data: {id: id}
          beforeSend: (xhr) ->
            xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'))
          success: (data) ->
            $(t).parent().parent().parent().slideUp()
            if window.location.pathname.match(/^\/user\/\w*\/\d*$/i)
              Turbolinks.visit("/")
          error: (data) ->
            alert("An error occured deleting your post: #{data.statusText}")