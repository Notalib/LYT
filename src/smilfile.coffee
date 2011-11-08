# This class models an SMIL (Synchronized Multimedia Integration Language) file
#
#

do ->
  class LYT.SMILDocument
    # The constructor takes 1 argument: The URL of the SMIL-file
    constructor: (@url) ->
      deferred = jQuery.Deferred()
      deferred.promise this
      
      options = 
        url:      @url
        dataType: "xml"
        async:    true
        cache:    true
        success:  (xml, status, xhr) =>
          @sequences = parseSequences jQuery(xml)
          deferred.resolve()
        error: (xhr, status, error) =>
          deferred.reject(xhr, status, error)
          
      jQuery.ajax @url, options
    
    # Get the media references for a given offset
    mediaFor: (offset = 0) ->
      for sequence in @sequences
        for segment in sequence.segments
          return segment if segment.start <= offset < segment.end
      return null
  
  # ---------------
  
  # Non-public helper function to parse the `<seq>` elements
  parseSequences = (xml) ->
    sequences = []
    xml.find("body > seq").each ->
      element = jQuery this
      sequences.push {
        duration: parseFloat(element.attr("dur")) || 0 # get the duration
        segments: parseSequence element
      }
    
    return sequences
  
  # TODO: Right now, this only handles text and audio - not images!
  parseSequence = (sequence) ->
    data = []
    sequence.find("par").each ->
      par = jQuery this
      text  = par.find("text").first()
      audio = par.find("seq audio").first()
      data.push {
        id: par.attr "id"
        start: parseTime audio.attr("clip-begin")
        end:   parseTime audio.attr("clip-end")
        text:
          id:  text.attr "id"
          src: text.attr "src"
        audio:
          id:  audio.attr "id"
          src: audio.attr "src"
      }
    
    return data
  
  # TODO: SMIL defines several ways to define a time-offset. Right now, this only handles the "npt=XX.Xs" format
  parseTime = (value) ->
    m = value.match /^npt=([\d.]+)s/
    return 0 unless m
    parseFloat(m[1]) || 0
    
  
