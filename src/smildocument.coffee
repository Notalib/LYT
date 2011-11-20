do ->
  
  # Class to model a SMIL document
  class LYT.SMILDocument extends LYT.DTBDocument
    constructor: (url) ->
      super url, (deferred) =>
        mainSequence = @xml.find("body > seq:first")
        @duration    = parseFloat(mainSequence.attr("dur")) or 0
        @pars        = parseMainSequence mainSequence
        metadata = @getMetadata()
        @absoluteOffset = if metadata.totalElapsedTime? then parseTime(metadata.totalElapsedTime.content) else null
    
    getParByTime: (offset = 0) ->
      for par in @pars
        return par if par.start <= offset < par.end
      
      return null
  
  # -------
  
  # ## Privileged
  
  # Parse the main `<seq>` element's `<par>` (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseMainSequence = (sequence) ->
    pars = []
    sequence.children("par").each ->
      par = jQuery this
      audio = par.find "audio:first"
      text  = par.find "text:first"
      pars.push {
        id:    par.attr "id"
        start: parseNPT audio.attr("clip-begin")
        end:   parseNPT audio.attr("clip-end")
        audio:
          id:  audio.attr "id"
          src: audio.attr "src"
        text:
          id:  text.attr "id"
          src: text.attr "src"
      }
    
    return pars
  
  # Parse the Normal Play Time format (npt=ss.s) (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseNPT = (string) ->
    time = string.match /^npt=([\d.]+)s?$/i
    parseFloat(time?[1]) or 0
  
