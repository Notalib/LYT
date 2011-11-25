class LYT.TextContentDocument extends LYT.DTBDocument
  getElementById: (id) ->
    @source.find("##{id}").first().clone()
  
