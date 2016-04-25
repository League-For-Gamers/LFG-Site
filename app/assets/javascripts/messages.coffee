get_new_messages = (id, uid, repeat) ->
  if Foundation.utils.S("meta[name='unique']").attr('content') == uid
    latest_timestamp = Foundation.utils.S(".chat-card").children().first().data("timestamp")
    $.ajax
      url: "/messages/#{id}/newer"
      type: 'GET'
      dataType: 'html'
      data: {'timestamp': latest_timestamp}
      complete: (data) ->
        Foundation.utils.S(".chat-card").prepend(data.responseText)
        decrypt_messages()
        if repeat
          window.setTimeout(get_new_messages, 10000, id, uid, true)

decrypt_messages = ->
  new Promise((resolve, reject) ->
    console.log "Decrypting messages..."
    LFGCrypto.get_private_key().then (private_key) ->
      for message in Foundation.utils.S(".message.ver-2.encrypted")
        LFGCrypto.decrypt_message(message, private_key)
  )

$ ->
  if !!window.location.pathname.match(/^\/messages$/i)
    decrypt_messages()
  if !!window.location.pathname.match(/^\/messages\/\d+/i)
    loading_messages = false
    end_of_chat = false
    can_send = false
    sending = false
    public_keys = []
    chat_id = window.location.pathname.match(/\/messages\/(\d+)/i)[1]
    console.log "Chat ID: #{chat_id}"
    console.log "Finished initial config"
    decrypt_messages()

    users = Foundation.utils.S("meta[name=users]").attr("content").split(",")

    for user in users
      LFGCrypto.get_public_key(user).then (key) ->
        public_keys.push key
        if public_keys.length == users.length
          can_send = true

    Foundation.utils.S('#new_private_message').on 'submit', (e) ->
      e.preventDefault()
      if can_send and !sending and Foundation.utils.S('#new_private_message #fake_body').val().trim().length > 0
        form = Foundation.utils.S(this)
        sending = true # Ensure we can't send multiple messages at once. Avoides duplicates.

        message = Foundation.utils.S('#new_private_message #fake_body').val().trim()
        Foundation.utils.S('#new_private_message #fake_body').val('')
        
        openpgp.encrypt({data: message, publicKeys: public_keys}).then (crypt) ->
          Foundation.utils.S('#new_private_message #private_message_body').val(crypt.data)
          $.ajax
            url: window.location.pathname
            type: 'POST'
            dataType: 'json'
            data: form.serialize()
            complete: (data) ->
              $('#new_private_message #private_message_body').val('')
              get_new_messages(chat_id, Foundation.utils.S("meta[name='unique']").attr('content'), false)
              sending = false

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

    get_new_messages(chat_id, Foundation.utils.S("meta[name='unique']").attr('content'), true) 
