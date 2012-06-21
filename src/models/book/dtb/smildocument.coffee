# Requires `/common`  
# Requires `/support/lyt/utils`  
# Requires `dtbdocument`  

# -------------------

#    getTextContentReferences: ->
#      urls = []
#      for segment in @segments when segment.text?
#        url = segment.text.src.replace /#.*$/, ""
#        urls.push url if urls.indexOf(url) is -1
#      urls

do ->
  
  # Class to model a SMIL document
  class LYT.SMILDocument extends LYT.DTBDocument
    constructor: (section, url) ->
      super url, (deferred) =>
        mainSequence = @source.find("body > seq:first")
        @duration    = parseFloat(mainSequence.attr("dur")) or 0
        @segments    = parseMainSeqNode section, mainSequence
        @absoluteOffset = LYT.utils.parseTime(@getMetadata().totalElapsedTime?.content) or null

    # Caveat emptor: returns raw segments
    getSegmentById: (id) ->
      for segment, index in @segments
        return segment if segment.id == id
      
      return null
      
    # Caveat emptor: returns raw segments
    getSegmentAtOffset: (offset = 0) ->
      offset = 0 if offset < 0
      for segment, index in @segments
        return segment if segment.start <= offset < segment.end
      
      return null
    
    getAudioReferences: ->
      urls = []
      for segment in @segments when segment.audio.src
        urls.push segment.audio.src if urls.indexOf(segment.audio.src) is -1
      urls
        
  
  # -------
  
  # ## Privileged
  
  # Parse the main `<seq>` element's `<par>`s (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseMainSeqNode = (section, sequence) ->
    clips = []
    sequence.children("par").each ->
      clips = clips.concat parseParNode(section, jQuery(this))
    previous = null
    for clip, index in clips
      clip = new LYT.Segment section, clip
      clip.index = index
      clip.previous = previous
      previous?.next = clip
      clips[index] = clip
      previous = clip
    clips
  
  
  # Parse a `<par>` node
  idCounter = 1
  parseParNode = (section, par) ->
    # Find the `text` node, and parse it separately
    text = parseTextNode par.find("text:first")
    
    # TODO: This function has to be rewritten so it can take the following
    # into account when collapsing clips into one:
    #  - Changing source file
    #  - Changing id
    #  - Non-adjacent clips (i.e. some parts of an audio file that should
    #    be skipped)
    #  - Changing text

    # Find all nested `audio` nodes
    clips = par.find("> audio, seq > audio").map ->
      audio = jQuery this
      
      id:    par.attr("id")
      start: parseNPT audio.attr("clip-begin")
      end:   parseNPT audio.attr("clip-end")
      text:  text
      section: section
      audio:
        id:  audio.attr "id"
        src: audio.attr "src"
    
    clips = jQuery.makeArray clips
    clips.sort (a, b) -> a.start - b.start
    
    # Collapse audio references into 1
    clip = clips[0]
    clip.end = clips[clips.length-1].end
    clip.id or= "!auto_#{idCounter++}"
    return [clip]
  
  
  parseTextNode = (text) ->
    return null if text.length is 0
    id:  text.attr "id"
    src: text.attr "src"
  
  
  # Parse the Normal Play Time format (npt=ss.s) (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseNPT = (string) ->
    time = string.match /^npt=([\d.]+)s?$/i
    parseFloat(time?[1]) or 0
  
