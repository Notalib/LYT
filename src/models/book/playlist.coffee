# Requires `/common`  

# -------------------

# This class models a "playlist" of book sections

class LYT.Playlist
  
  constructor: (@book, initialSectionId = null) ->
    @sections  = @book.nccDocument.sections
    
    deferred = jQuery.Deferred()
    deferred.promise this
    current = @setCurrentSection initialSectionId
    unless current
      log.error "Playlist: Failed to find initial section"
      deferred.reject this
      return
    
    current.done =>
      log.message "Playlist: Loaded initial section"
      deferred.resolve this
    
    current.fail =>
      log.error "Playlist: Failed to load initial section"
      deferred.reject this
  
  hasNextSection: ->
    @currentIndex < @sections.length-1
  
  hasPreviousSection: ->
    @currentIndex > 0
  
  getNextSection: ->
    return null unless @hasNextSection()
    index = @currentIndex + 1
    @sections[index].load()
  
  getPreviousSection: ->
    return null unless @hasPreviousSection()
    index = @currentIndex - 1
    @sections[index].load()
  
  getCurrentSection: ->
    @sections[@currentIndex]?.load() or null
  
  next: ->
    return null unless @hasNextSection()
    @currentIndex++
    @getCurrentSection()
  
  previous: ->
    return null unless @hasPreviousSection()
    @currentIndex--
    @getCurrentSection()
  
  setCurrentSection: (id = null) ->
    if !!id
      for section, index in @sections
        if section.id is id
          @currentIndex = index
          return @getCurrentSection()
      log.warn "Playlist: Couldn't find section #{id}"
    
    @currentIndex = 0
    @getCurrentSection()


