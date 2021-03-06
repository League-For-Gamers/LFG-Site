get_new_messages = (id, uid) ->
  if Foundation.utils.S("meta[name='unique']").attr('content') == uid
    latest_timestamp = Foundation.utils.S(".chat-card").children().first().data("timestamp")
    $.ajax
      url: "/messages/#{id}/newer"
      type: 'GET'
      dataType: 'html'
      data: {'timestamp': latest_timestamp}
      complete: (data) ->
        Foundation.utils.S(".chat-card").prepend(data.responseText)
        window.setTimeout(get_new_messages, 10000, id, uid)

$ ->
  if window.location.pathname.match(/\/messages\/\d+/i)
    loading_messages = false
    end_of_chat = false
    chat_id = window.location.pathname.match(/\/messages\/(\d+)/i)[1]

    Foundation.utils.S(window).scroll ->
      # Each browser seems to treat all the elements used in this differently.
      # So, this is the only method that seems to work for all
      if @ie_browser or @ff_browser
        detected = document.documentElement.clientHeight + document.documentElement.scrollTop >= document.body.scrollHeight - 300
      else
        detected = window.innerHeight + document.body.scrollTop >= document.body.scrollHeight - 300

      if detected and !end_of_chat and !loading_messages
        loading_messages = true
        Foundation.utils.S("#loading-message").show()
        last_timestamp = Foundation.utils.S(".chat-card").children().last().data("timestamp")
        $.ajax
          url: "/messages/#{chat_id}/older"
          type: 'GET'
          dataType: 'html'
          data: {'timestamp': last_timestamp}
          complete: (data) ->
            if data.responseText.length == 0
              end_of_chat = true
            Foundation.utils.S(".chat-card").append(data.responseText)
            loading_messages = false
            Foundation.utils.S("#loading-message").hide()

    get_new_messages(chat_id, Foundation.utils.S("meta[name='unique']").attr('content')) 
