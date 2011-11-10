

do ->
  # RegExp patterns for matching URLs
  AUDIO = /[^\/]+\.mp3$/i
  SMIL  = /[^\/]+\.smil$/i
  NCC   = /ncc.html?$/i
  
  # FIXME: This entire class is in dire need of refactoring
  class LYT.Book
    @load: (id) ->
      deferred = jQuery.Deferred()
      book = new LYT.Book(id)
      book.then (book) ->
        deferred.resolve book
      book.fail ->
        deferred.reject null
      deferred
    
    constructor: (@id) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
      @smilDocuments = {}
      @textDocuments = {}
      @nccDocument   = null
      
      issue = ->
        issued = LYT.rpc "issueContent", @id
        issued.then getResources
        issued.fail -> deferred.reject()
      
      getResources = =>
        got = LYT.rpc "getContentResources", @id
        ncc = null
        got.then (@resources) =>
          for own localUri, uri of @resources
            @resources[localUri] =
              url:      uri
              document: null
            
            if localUri.match /ncc\.html?$/i then ncc = @resources[localUri]
          
          getNCC ncc
        
        got.fail -> deferred.reject()
      
      getNCC = (obj) =>
        ncc = new LYT.NCCDocument(obj.url)
        
        ncc.then (document) =>
          obj.document = document
          @nccDocument = document
          deferred.resolve()
        
        ncc.fail ->
          deferred.reject()
      
      issue(@id)
    
    # TODO: Move this to NCCDocument?
    preloadSection: (section = null) ->
      deferred = jQuery.Deferred()
      
      section = @nccDocument.findSection section
      
      deferred.reject(null) unless section?
      
      sections = section.flatten()
      
      watch = []
      
      for section in sections
        file = section.url.replace /#.*$/, ""
        section.absoluteURL or= @resources[file].url
        
        unless section.document?
          section.document = new LYT.SMILDocument section.absoluteURL
          watch.push section.document
      
      if watch.length is 0
        deferred.resolve sections
      else
        jQuery.when.apply(null, watch)
          .then -> deferred.resolve(sections)
          .fail -> deferred.reject()
      
      return deferred
    
    resolveURL: (filename) ->
      filename = filename.replace /#.*$/, ""
      "#{@baseURL}/#{filename}"
    
    mediaFor: (section = null, offset = null) ->
      deferred = jQuery.Deferred()
      
      preload = @preloadSection section
      preload.done (sections) =>
        media = null
        until media? or sections.length is 0
          section = sections.shift()
          media = section.document.getParByTime offset or 0
          if media
            media.audio = @resources[media.audio.src]?.url
            
            [txtfile, txtid] = media.text.src.split "#"
            unless @resources[txtfile].document # and @resources[file].document.state() isnt "pending"
              @resources[txtfile].document = new LYT.TextContentDocument @resources[txtfile].url
              @resources[txtfile].document.done ->
                media.text = @resources[txtfile].document.getTextById txtid
                deferred.resolve media
            else
              media.text  = @resources[txtfile].document.getTextById txtid
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
  
