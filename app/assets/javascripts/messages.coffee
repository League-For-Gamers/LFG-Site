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

prompt_for_password = ->
  new Promise((resolve, reject) ->
    # TODO: Replace with a proper on-screen password field
    return resolve(prompt("Enter your PGP key password"))
  )

decrypt_private_key = (key, password) ->
  new Promise((resolve, reject) ->
    pass = password | btoa(window.sessionStorage.getItem('pass')) || btoa(window.localStorage.getItem('pass'))
    if key.decrypt(pass)
      if window.localStorage.getItem('pass') != null
        window.localStorage.setItem('pass', atob(pass))
      else
        window.sessionStorage.setItem('pass', atob(pass))
      return resolve(key)
    # User must be using their own key
    else
      prompt_for_password().then (password) ->
        return resolve(decrypt_private_key(key, password))
  )

get_private_key = ->
  new Promise((resolve, reject) ->
    key = window.sessionStorage.getItem('pkey')
    if key != null
      decrypt_private_key(openpgp.key.readArmored(key).keys[0]).then (key) ->
        return resolve(key)
    else
      $.ajax
        url: '/get_private_key'
        type: 'GET'
        dataType: 'plain'
        complete: (data) ->
          window.sessionStorage.setItem('pkey', data.responseText)
          decrypt_private_key(openpgp.key.readArmored(data.responseText).keys[0]).then (key) ->
            return resolve(key)
  )

get_public_key = (user) ->
  new Promise((resolve, reject) ->
    $.ajax
      url: "/user/#{user}/pubkey"
      type: 'GET'
      dataType: 'plain'
      complete: (data) ->
        return resolve(openpgp.key.readArmored(data.responseText).keys[0])
  )

decrypt_messages = ->
  for message in Foundation.utils.S(".message.ver-2.encrypted")
    decrypt_message(message)

decrypt_message = (message) ->
  new Promise((resolve, reject) ->
    body = Foundation.utils.S(message).find(".body").data('content')
    get_private_key().then (private_key) ->
      openpgp.decrypt({message: openpgp.message.readArmored(body), privateKey: private_key}).then (data) ->
        Foundation.utils.S(message).find(".body").data('content', '')
        Foundation.utils.S(message).find(".body").text(data.data)
        Foundation.utils.S(message).removeClass("encrypted")
        return resolve(true)
  )

$ ->
  if window.location.pathname.match(/^\/messages$/i)
    decrypt_messages()
  if window.location.pathname.match(/^\/messages\/\d+/i)
    loading_messages = false
    end_of_chat = false
    chat_id = window.location.pathname.match(/\/messages\/(\d+)/i)[1]
    users = Foundation.utils.S("meta[name=users]").attr("content").split(",")
    public_keys = []

    for user in users
      get_public_key(user).then (key) ->
        public_keys.push key

    decrypt_messages()

    Foundation.utils.S('#new_private_message').on 'submit', (e) ->
      e.preventDefault()

      form = Foundation.utils.S(this)

      message = Foundation.utils.S('#new_private_message #fake_body').val()
      Foundation.utils.S('#new_private_message #private_message_body').val('')
      
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
