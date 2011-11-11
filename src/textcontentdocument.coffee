class LYT.TextContentDocument extends LYT.DTBDocument
  getTextById: (id) ->
    text = @xml.find("##{id}").first().text()
    jQuery.trim text
  
