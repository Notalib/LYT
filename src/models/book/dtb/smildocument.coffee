# Requires `/common`
# Requires `/support/lyt/utils`
# Requires `dtbdocument`

# -------------------

do ->

  # Class to model a SMIL document
  class LYT.SMILDocument extends LYT.DTBDocument
    constructor: (url, book) ->
      super url, (deferred) =>
        mainSequence = @source.find("body > seq:first")
        @book        = book
        @duration    = parseFloat(mainSequence.attr("dur")) or 0
        @segments    = parseMainSeqNode mainSequence, this
        @absoluteOffset = LYT.utils.parseTime(@getMetadata().totalElapsedTime?.content) or null
        @filename = @url.split('/').pop()

    getSegmentById: (id) ->
      for segment, index in @segments
        return segment if segment.id == id

      return null

    # Returns the segment with the given id, or the segment
    # containing the element (often a <text>) with the given id
    getContainingSegment: (id) ->
      segment = @getSegmentById id
      return segment if segment

      for segment, index in @segments
        return segment if segment.el.find("##{id}").length > 0

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
  parseMainSeqNode = (sequence, smil) ->
    segments = []
    parData = []
    sequence.children("par").each ->
      parData = parData.concat parseParNode jQuery(this)
    previous = null
    for segment, index in parData
      segment = new LYT.Segment segment, smil
      segment.index = index
      segment.previous = previous
      previous?.next = segment
      segments.push segment
      previous = segment

    segments

  # Parse a `<par>` node
  idCounts = {}
  parseParNode = (par) ->
    # Find the `text` node, and parse it separately
    text = parseTextNode par.find("text:first")

    # Find all nested `audio` nodes
    clips = par.find("> audio, seq > audio").map ->
      audio = jQuery this

      id:          par.attr("id") or "__LYT_auto_#{audio.attr('src')}_#{idCounts[audio.attr('src')]++}"
      start:       parseNPT audio.attr("clip-begin")
      end:         parseNPT audio.attr("clip-end")
      text:        text
      canBookmark: par.attr('id')?
      audio:       src: audio.attr "src"
      smil:        element: audio
      par:         par

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

