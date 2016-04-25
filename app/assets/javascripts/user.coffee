generate_keypair = (name, password) ->
  new Promise((resolve, reject) ->
    console.log "Kicking off generation with password"
    options = {
      userIds: [{name: name}],
      numBits: 4096,
      passphrase: password
    }
    openpgp.generateKey(options).then (key) -> 
      return resolve(key)
  )
active_hide_by_variable = (selector, variable) ->
  if variable
    Foundation.utils.S(selector).addClass('unhide')
  else
    Foundation.utils.S(selector).removeClass('unhide')
  return

hide_by_variable = (selector, variable) ->
  if variable
    Foundation.utils.S(selector).removeClass('hidden')
  else
    Foundation.utils.S(selector).addClass('hidden')
  return
$ ->
  if window.location.pathname.match(/^\/generate_keys$/)
    interrupted = false
    active_hide_by_variable('#finalize_form',false)
    pass = btoa(window.sessionStorage.getItem('pass')) || btoa(window.localStorage.getItem('pass'))
    name = Foundation.utils.S("meta[name=username]").attr('content')
    generate_keypair(name, pass).then (key) ->
      console.log "Key generated"
      unless interrupted
        Foundation.utils.S('#keys_form #public_key').val(key.publicKeyArmored)
        Foundation.utils.S('#keys_form #private_key').val(key.privateKeyArmored)
        data = Foundation.utils.S('#keys_form').serialize()
        $.post(Foundation.utils.S('#keys_form').attr('action'), data).then ->
          active_hide_by_variable('.loading-ring',false)
          active_hide_by_variable('#finalize_form',true)
        return

    Foundation.utils.S('#manually_set_button').click ->
      interrupted = true
      active_hide_by_variable('.loading-ring',false)
      hide_by_variable('#manually_set_button', false)
      active_hide_by_variable('#finalize_form',false)
      Foundation.utils.S('#manual_password_container').addClass("unhide")

    Foundation.utils.S('#manual_password').on 'propertychange change keyup paste input', ->
      if Foundation.utils.S('#manual_password').val() == Foundation.utils.S('#manual_password_confirm').val() and Foundation.utils.S('#manual_password').val() != ""
        Foundation.utils.S('#generate_button').removeAttr('disabled')
      else
        Foundation.utils.S('#generate_button').attr('disabled', 'disabled')

    Foundation.utils.S('#manual_password_confirm').on 'propertychange change keyup paste input', ->
      if Foundation.utils.S('#manual_password').val() == Foundation.utils.S('#manual_password_confirm').val() and Foundation.utils.S('#manual_password').val() != ""
        Foundation.utils.S('#generate_button').removeAttr('disabled')
      else
        Foundation.utils.S('#generate_button').attr('disabled', 'disabled')

    Foundation.utils.S('#generate_button').click ->
      
      if Foundation.utils.S('#manual_password').val() == Foundation.utils.S('#manual_password_confirm').val()
        active_hide_by_variable('#manual_password_container',false)
        active_hide_by_variable('.loading-ring',true)
        generate_keypair(name, Foundation.utils.S('#manual_password').val()).then (key) ->
          console.log "Key generated"
          Foundation.utils.S('#keys_form #public_key').val(key.publicKeyArmored)
          Foundation.utils.S('#keys_form #private_key').val(key.privateKeyArmored)
          data = Foundation.utils.S('#keys_form').serialize()
          $.post(Foundation.utils.S('#keys_form').attr('action'), data).then ->
            active_hide_by_variable('.loading-ring',false)
            active_hide_by_variable('#finalize_form',true)

    return
  if window.location.pathname.match(/\/account/)
    Foundation.utils.S('#new_favourite_game').click ->
      id = Foundation.utils.S('#favourite_games').children().length
      html = $.parseHTML "<input name='user[games][#{id}][name]' type='text' id='user_games_name'>"
      Foundation.utils.S('#favourite_games').append html
      return
    Foundation.utils.S('#new_skill').click ->
      # this is so dirtyyyyy
      id = Date.now()
      html = Foundation.utils.S('#skills').children()[0].outerHTML.replace(/selected=\"selected\" /g, "")
      html = html.replace(/\[(\d)\]/g, "[#{id}]").replace(/_\d_/g, "_#{id}_")
      html = html.replace /type="hidden" value="\d+"/, 'type="hidden"'
      id = html.match(/id=\"(user_skills_attributes_\d+_id)\"/)[1]
      Foundation.utils.S('#skills').append html
      Foundation.utils.S("##{id}").val("")
      return
  if window.location.pathname.match(/\/user\/([\d\w]*)/i)
    # Well this is gross.
    Foundation.utils.S('.bio-card .bottom .buttons').height( -> Foundation.utils.S(this).children().map(->
      Foundation.utils.S(this).height()
    ).sort().last()[0])

    Foundation.utils.S('.edit-section .hide').click -> 
      section = Foundation.utils.S(this).data('section')
      t = this
      $.ajax
        url: '/ajax/user/hide'
        type: 'POST'
        dataType: 'text'
        data: {'section': section}
        beforeSend: (xhr) ->
          xhr.setRequestHeader('X-CSRF-Token', Foundation.utils.S('meta[name="csrf-token"]').attr('content'))
        complete: (data) ->
          Foundation.utils.S(t).toggleClass('disabled')
          Foundation.utils.S(".#{section}-card .hidden-section").toggleClass("active")
  if window.location.pathname.match(/\/search/i)
    Foundation.utils.S('#search-filter').change ->
      Foundation.utils.S('#filtered-search-form').submit()
    Foundation.utils.S('#search-bar').on 'propertychange change keyup paste input', ->
      Foundation.utils.S('#hidden-search-field').val(Foundation.utils.S(this).val())
