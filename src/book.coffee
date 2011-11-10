do ->
  class LYT.Book
    constructor: (@id) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
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
        
        ncc.fail -> deferred.reject()
      
      issue(@id)
    
    preloadSection: (section = null) ->
      deferred = jQuery.Deferred()
      
      section = @nccDocument.findSection section
      unless section?
        deferred.reject(null)
        return
      
      sections = section.flatten()
      
      documents = []
      
      for section in sections
        unless section.document
          file = section.url.replace /#.*$/, ""
          url  = @resources[file]?.url
          unless url?
            deferred.reject(null) 
            return
          
          section.document = new LYT.SMILDocument url
        
        documents.push section.document
      
      jQuery.when.apply(null, documents)
        .then -> deferred.resolve(sections)
        .fail -> deferred.reject(null)
      
      return deferred
    
    mediaFor: (section = null, offset = null) ->
      deferred = jQuery.Deferred()
      
      preload = @preloadSection section
      preload.fail -> deferred.resolve null
      
      preload.done (sections) =>
        for section in sections
          par = section.document.getParByTime offset or 0
          if par
            par.audio = @resources[par.audio.src]?.url or null
            [txtfile, txtid] = par.text.src.split "#"
            if @resources[txtfile]
              unless @resources[txtfile].document
                @resources[txtfile].document = new LYT.TextContentDocument @resources[txtfile].url
              @resources[txtfile].document.done =>
                par.text = @resources[txtfile].document.getTextById txtid
                deferred.resolve par
            else
              media.text = null
              deferred.resolve par
            
            return
          
        deferred.resolve null
      
      return deferred
    
  
