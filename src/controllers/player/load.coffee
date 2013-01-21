# Requires `/controllers/player/command`
# -------------------

class LYT.player.load extends LYT.player.command

  constructor: (player, @book) ->
    super player
    log.message 'Player: command load: intializing'
    load.done (book) => log.message "Player: command load: loading book #{@book} done"
    load.fail (book) => log.message "Player: command load: loading book #{@book} failed"

  run: ->
    return if @player.book? and @player.book.id is @book
    promise = LYT.Book.load @book
    
    log.message "Player: command load: loading book #{@book}"
    
    promise.done (book) ->
      @player.book = book
      # TODO: Move to view method
      jQuery("#book-duration").text @player.book.totalTime
      
    promise

