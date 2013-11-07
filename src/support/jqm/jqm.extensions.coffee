# This replaces the standard jQuery Mobile `showPageLoadingMsg` function with
# one that accepts an optional argument specifying the loading message to
# display. If no argument is given, the function does the same as always: the
# default message (i.e. `$.mobile.loadingMessage`) is shown.

do ->
  # Must wait for document load, before `showPageLoadingMsg` can be
  # redefined (it's only defined _after_ the `mobileinit` event)
  jQuery ->
    # "Save" the original function
    showPageLoadingMsg = jQuery.mobile.showPageLoadingMsg

    # Define the new one
    jQuery.mobile.showPageLoadingMsg = (message) ->
      # If no message was passed, just show the standard message
      unless message?
        showPageLoadingMsg()
        return

      # "Save" the original/default message
      original = jQuery.mobile.loadingMessage

      # Set the custom message
      jQuery.mobile.loadingMessage = String(message)

      # Call the original function
      showPageLoadingMsg()

      # Restore the original/default message
      jQuery.mobile.loadingMessage = original


