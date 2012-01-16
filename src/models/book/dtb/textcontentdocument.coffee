# Requires `/common`  
# Requires `dtbdocument`  

# -------------------

# This class models a Diasy Text Content document (an XHTML file
# containing the text of a book)

class LYT.TextContentDocument extends LYT.DTBDocument
  getContentById: (id) ->
    container = jQuery @source.get(0).createElement("DIV")
    element = @source.find("##{id}").first()
    container.append element.clone()
    
    sibling = element.next()
    until sibling.length is 0 or sibling.attr "id"
      container.append sibling.clone()
      sibling = sibling.next()
    
    container
  
