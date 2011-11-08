do ->
  # RegExp patterns for matching URLs
  AUDIO = /[^\/]+\.mp3$/i
  SMIL  = /[^\/]+\.smil$/i
  NCC   = /ncc.html?$/i
  
  class LYT.Book
    @load: (id) ->
      deferred = jQuery.Deferred()
      book = new LYT.Book(id)
      book.then (book) ->
        deferred.resolve book
      book.fail ->
        deferred.reject null
    
    constructor: (@id) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
      @smilDocuments = {}
      
      issue = ->
        issued = LYT.rpc "issueContent", @id
        issued.then getResources
        issued.fail -> deferred.reject()
      
      getResources = =>
        got = LYT.rpc "getContentResources", @id
        
        got.then (list) =>
          @resources = parseContentResources list
          @baseURL   = @resources.ncc.replace /\/[^\/]+\.html?$/, ""
          getNCC @resources.ncc
        
        got.fail -> deferred.reject()
      
      getNCC = (url) =>
        @nccDocument = new LYT.NCCDocument(url)
        @nccDocument.then -> deferred.resolve()
        @nccDocument.fail -> deferred.reject()
      
      issue(@id)
    
    # TODO: Move this to NCCDocument?
    preloadSection: (section = null) ->
      deferred = jQuery.Deferred()
      
      if section?
        section = @nccDocument.findSection section
      else
        section = @nccDocument.firstSection()
      
      deferred.reject(null) unless section?
      
      console.log "Preloading section #{section.id}"
      subsections = section.flatten()
      
      console.log subsections
      watch = []
      for subsection in subsections
        subsection.absoluteURL or= @resolveURL(subsection.url)
        
        unless subsection.document?
          console.log "no document for subsection #{subsection.id}"
          subsection.document = new LYT.SMILDocument subsection.absoluteURL
          watch.push subsection.document
      
      if watch.length is 0
        deferred.resolve subsections
      else
        jQuery.when.apply(null, watch)
          .then -> deferred.resolve(subsections)
          .fail -> deferred.reject()
      
      return deferred
    
    resolveURL: (filename) ->
      filename = filename.replace /#.*$/, ""
      "#{@baseURL}/#{filename}"
    
    mediaFor: (section = null, offset = null) ->
      deferred = jQuery.Deferred()
      
      preload = @preloadSection section
      preload.done (sections) =>
        console.log "Preload done"
        media = null
        until media? or sections.length is 0
          section = sections.shift()
          media = section.document.mediaFor offset or 0
          if media
            media.text  = @nccDocument.getTextById media.text.src
            media.audio = @resolveURL media.audio.src
        
        deferred.resolve media
      
      preload.fail ->
        deferred.resolve null
      
      deferred
  
  parseContentResources = (list) ->
    resources =
      smil:  {}
      audio: {}
      ncc:   null
    
    for url in list
      if      (m = url.match AUDIO) then resources.audio[m[0]] = { url: url }
      else if (m = url.match SMIL)  then resources.smil[m[0]] = { url: url }
      else if (m = url.match NCC)   then resources.ncc = url
    
    return resources
  
