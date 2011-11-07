class LYT.Book

  constructor: (@baseURI, @id) ->
    @nccFile = new LYT.NCCFile "#{@baseURI}/#{@id}.html"
  
  audioFiles: ->
    files = []
    for smilFile in @nccFile.smilFiles
      files = files.concat smilFile.audioFiles()
    ("#{@baseURI}/#{file}" for file in files)
  
  textAtOffset: (audio, offset) ->
    audio = audio.split(/\//).pop()
    for smilFile in @nccFile.smilFiles
      if smilFile.audioFiles().indexOf(audio) isnt -1
        # FIXME: This is just terrible
        for segment in smilFile.sequences[0].segments
          if segment.audio.start <= offset <= segment.audio.end
            return {
              id:    segment.id
              start: segment.audio.start
              end:   segment.audio.end
              text:  jQuery.trim @nccFile.getTextById(segment.text.src)
            }
    null