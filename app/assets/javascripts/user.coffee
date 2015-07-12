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
      html = $('#skills').children()[0].outerHTML.replace(/selected=\"selected\" /g, "").replace(/value=\".*\"/g, "")
      html = html.replace(/\[(\d)\]/g, "[#{id}]").replace(/_\d_/g, "_#{id}_")
      html = html.replace /type="hidden" value="\d+"/, 'type="hidden"'
      $('#skills').append html
      return
  if window.location.pathname.match(/\/user\/([\d\w]*)/i)
    $('.edit-section .hide').click -> 
      section = $(this).data('section')
      t = this
      $.ajax
        url: '/ajax/user/hide'
        type: 'POST'
        dataType: 'application/json'
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