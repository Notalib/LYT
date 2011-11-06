# TODO: How to best model this domain? MP3-file has sequences with text? Text-data refers to sequence, which refers to MP3? Sequences refer to... etc

do =>
  class @SMILFile
  
    constructor: (@url) ->
      # TODO: This shares some parts with the NCCFile class. Make a common ancestor class for both?
      
      options = 
        url:      @url
        dataType: "xml"
        # FIXME: It really should be asynchronous...
        async:    false
        cache:    false
        success:  (xml, status, xhr) =>
          @sequences = parseSequences jQuery(xml)
        # FIXME: Handle errors
          
      jQuery.ajax @url, options
  
  parseSequences = (xml) ->
    sequences = []
    xml.find("body > seq").each ->
      element = jQuery this
      sequences.push {
        duration: parseFloat(element.attr("dur")) || 0 # get the duration
        contents: parseSequence element
      }
    
    sequences
  
  # TODO: Right now, this only handles text and audio
  parseSequence = (sequence) ->
    data = []
    sequence.find("par").each ->
      par = jQuery this
      text  = par.find("text").first()
      audio = par.find("seq audio").first()
      data.push {
        id: par.attr "id"
        text:
          id:  text.attr("id")
          src: text.attr("src")
        audio:
          id:    audio.attr "id"
          start: parseTime audio.attr("clip-begin")
          end:   parseTime audio.attr("clip-end")
          src:   audio.attr "src"
      }
    
    return data
  
  # TODO: SMIL defines several ways to define a time-offset. Right now, this only handles the "npt=XX.Xs" format
  parseTime = (value) ->
    m = value.match /^npt=([\d.]+)s/
    return 0 unless m
    parseFloat(m[1]) || 0
    
  
