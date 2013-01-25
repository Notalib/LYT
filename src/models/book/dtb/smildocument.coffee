# Requires `/common`  
# Requires `/support/lyt/utils`  
# Requires `dtbdocument`  

# -------------------

do ->
  
  # Class to model a SMIL document
  class LYT.SMILDocument extends LYT.DTBDocument
    constructor: (section, url) ->
      super url, (deferred) =>
        mainSequence = @source.find("body > seq:first")
        @duration    = parseFloat(mainSequence.attr("dur")) or 0
        @segments    = parseMainSeqNode section, mainSequence
        @absoluteOffset = LYT.utils.parseTime(@getMetadata().totalElapsedTime?.content) or null

    getSegmentById: (id) ->
      for segment, index in @segments
        return segment if segment.id == id
      
      return null
      
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
  idCounts = {}
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
      
      id:          par.attr("id") or "__LYT_auto_#{clip.audio.src + '_' + idCounts[clip.audio.src]++}"
      start:       parseNPT audio.attr("clip-begin")
      end:         parseNPT audio.attr("clip-end")
      text:        text
      section:     section
      canBookmark: par.attr('id')?
      audio:       src: audio.attr "src"
      smil:        element: audio
    
    clips = jQuery.makeArray clips

    return [] if clips.length == 0

    # Collapse adjacent audio clips
    reducedClips = []
    i = 0
    while clip = clips[i]
      i++
      if lastClip? and clip.audio.src is lastClip.audio.src
        # Ignore small differences between start and end,
        # since this can occur as a result of rounding errors
        if Math.abs(clip.start - lastClip.end) < 0.001
          lastClip.end = clip.end
          continue
      if clip.id?
        clip.canBookmark = true
      else
        clip.canBookmark = false
        idCounts[clip.audio.src] or= 1
        clip.id = "__LYT_auto_#{clip.audio.src + '_' + idCounts[clip.audio.src]++}"
      lastClip = clip
      reducedClips.push clip

    return reducedClips


  parseTextNode = (text) ->
    return null if text.length is 0
    id:  text.attr "id"
    src: text.attr "src"
  
  
  # Parse the Normal Play Time format (npt=ss.s) (c.f. [DAISY 2.02](http://www.daisy.org/z3986/specifications/daisy_202.html#smilaudi))
  parseNPT = (string) ->
    time = string.match /^npt=([\d.]+)s?$/i
    parseFloat(time?[1]) or 0
  
