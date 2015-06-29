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
      $('#skills').append html
      return
