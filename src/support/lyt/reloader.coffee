# Only for use in development
# Reloads the page if a new build has been detected

do ->
  buildnumber = null
  check = ->
    $.ajax
      ifModified: true
      url: '.buildnumber'
      type: 'GET'
      success: (res) ->
        if buildnumber and buildnumber isnt res
          $('body').html('<h1>Reloading...</h1>');
          location.reload true
        buildnumber = res
        setTimeout check, 250

  check()
