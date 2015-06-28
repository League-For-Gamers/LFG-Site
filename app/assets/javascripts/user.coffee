$ ->
  if window.location.pathname.match(/\/user\/account/)
    $('#new_favourite_game').click ->
      id = $('#favourite_games').children().length
      html = $.parseHTML "<input name='user[games][#{id}][name]' type='text' id='user_games_name'>"
      $('#favourite_games').append html
      return
