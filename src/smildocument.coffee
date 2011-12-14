do ->
  
  # Class to model a SMIL document
  class LYT.SMILDocument extends LYT.DTBDocument
    constructor: (url) ->
      super url, (deferred) =>
        mainSequence = @source.find("body > seq:first")
        @duration    = parseFloat(mainSequence.attr("dur")) or 0
        @segments    = parseMainSeqNode mainSequence
        metadata = @getMetadata()
        @absoluteOffset = if metadata.totalElapsedTime? then parseTime(metadata.totalElapsedTime.content) else null
    
    getSegmentByTime: (offset = 0) ->
      for segment, index in @segments
        segment.index = index
        if segment.start <= offset < segment.end
          return segment
      
      return null
    
    getTextContentReferences: ->
      urls = []
      for segment in @segments when segment.text?
        url = segment.text.src.replace /#.*$/, ""
        urls.push url if urls.indexOf(url) is -1
      urls
    
    getAudioReferences: ->
      urls = []
      for segment in @segments when segment.audio.src
        urls.push segment.audio.src if urls.indexOf(segment.audio.src) is -1
      urls
        
  
  # -------
  
  # ## Privileged
  
  # Parse the main `<seq>` element's `<par>`s (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseMainSeqNode = (sequence) ->
    clips = []
    sequence.children("par").each ->
      clips = clips.concat parseParNode(jQuery(this))
    clips
  
  
  # Parse a `<par>` node
  parseParNode = (par) ->
    # Find the `text` node, and parse it separately
    text = parseTextNode par.find("text:first")
    
    # Find all nested `audio` nodes
    clips = par.find("seq > audio").map ->
      audio = jQuery this
      
      id:    par.attr "id"
      start: parseNPT audio.attr("clip-begin")
      end:   parseNPT audio.attr("clip-end")
      text:  text
      audio:
        id:  audio.attr "id"
        src: audio.attr "src"
    
    # return as a straight array
    jQuery.makeArray clips
  
  
  parseTextNode = (text) ->
    return null if text.length is 0
    id:  text.attr "id"
    src: text.attr "src"
  
  
  # Parse the Normal Play Time format (npt=ss.s) (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseNPT = (string) ->
    time = string.match /^npt=([\d.]+)s?$/i
    parseFloat(time?[1]) or 0
  
