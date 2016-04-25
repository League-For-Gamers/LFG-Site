class @LFGCrypto
  constructor: (@name) ->

  prompt_for_password = ->
    new Promise (resolve, reject) ->
      # TODO: Rewrite the fuck out of this
      console.log "Showing password prompt"
      Foundation.utils.S('.blackout').show()
      Foundation.utils.S('.blackout').data('usage', '#pgp-decrypt-form')
      Foundation.utils.S('.blackout').data('blockout', 'true')
      Foundation.utils.S('#pgp-decrypt-form').addClass('unhide')
      Foundation.utils.S('#pgp-decrypt-form form').on 'submit', (e) ->
        e.preventDefault()
        pass = Foundation.utils.S(this).find('#pgp_password').val()
        Foundation.utils.S(this).find('#pgp_password').val('')
        Foundation.utils.S('#pgp-decrypt-form').removeClass('unhide')
        Foundation.utils.S('.blackout').hide()
        Foundation.utils.S('.blackout').data('blockout', null)
        return resolve(pass)

  decrypt_private_key = (key, password) ->
    new Promise((resolve, reject) ->
      pass = password or btoa(window.sessionStorage.getItem('pass')) or btoa(window.localStorage.getItem('pass'))
      #console.log "Attempting decrypt of private key..."
      if key.decrypt(pass)
        #console.log "Success!"
        if window.localStorage.getItem('pass') != null
          window.localStorage.setItem('pass', atob(pass))
        else
          window.sessionStorage.setItem('pass', atob(pass))
        console.log "Password valid"
        resolve(key)
      # User must be using their own key
      else
        console.log "Password invalid..."
        prompt_for_password().then (password) ->
          resolve(decrypt_private_key(key, password))
      return
    )

  @get_private_key = ->
    new Promise( (resolve, reject) ->
      key = window.sessionStorage.getItem('pkey')
      if key != null
        decrypt_private_key(openpgp.key.readArmored(key).keys[0]).then (private_key) ->
          resolve(private_key)
      else
        $.ajax
          url: '/get_private_key'
          type: 'GET'
          dataType: 'plain'
          complete: (data) ->
            window.sessionStorage.setItem('pkey', data.responseText)
            decrypt_private_key(openpgp.key.readArmored(data.responseText).keys[0]).then (private_key) ->
              resolve(private_key)
            return
      return
    )

  @get_public_key = (user) ->
    new Promise (resolve, reject) ->
      keys_json = window.localStorage.getItem('public_keys')
      keys = {}
      if keys_json != undefined
        keys = JSON.parse keys_json
      if keys[user] != undefined
        return resolve(openpgp.key.readArmored(keys[user]).keys[0])
      else
        $.ajax
          url: "/user/#{user}/pubkey"
          type: 'GET'
          dataType: 'plain'
          complete: (data) ->
            keys[user] = data.responseText
            window.localStorage.setItem('public_keys', JSON.stringify(keys))
            return resolve(openpgp.key.readArmored(data.responseText).keys[0])
      return

  @decrypt_message = (message, private_key) ->
    new Promise (resolve, reject) ->
      body = Foundation.utils.S(message).find(".body").data('content')
      openpgp.decrypt({message: openpgp.message.readArmored(body), privateKey: private_key}).then (data) ->
        Foundation.utils.S(message).find(".body").data('content', '')
        Foundation.utils.S(message).find(".body").text(data.data)
        Foundation.utils.S(message).removeClass("encrypted")
        return resolve(true)

  @sign_message = (message, private_key) -> 
    new Promise (resolve, reject) ->
      # TODO: Some sort of serverside verification of signatures? A sort of MITM detection, maybe?
      openpgp.sign({data: message, privateKeys: private_key}).then (signed) ->
        return resolve signed.data
      return

  @verify_signature = (message, signature, public_key) ->
    new Promise (resolve, reject) ->
      # Transform into cleartext message...
      cleartextMessage = openpgp.cleartext.readArmored(signature)
      openpgp.verify(publicKeys: public_key, message: cleartextMessage).then (result) ->
        return reject(result) if !result.signatures[0].valid
        return reject(result) if result.data != message
        return resolve(result)
      return