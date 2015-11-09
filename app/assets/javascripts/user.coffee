$ ->
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
      id = html.match(/id=\"(user_skills_attributes_\d+_note)\"/)[1]
      Foundation.utils.S('#skills').append html
      Foundation.utils.S("##{id}").val("")
      return
  if window.location.pathname.match(/\/user\/([\d\w]*)/i)
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