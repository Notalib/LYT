# Requires `/common`  
# Requires `dtbdocument`  

# -------------------

# This class models a Diasy Text Content document (an XHTML file
# containing the text of a book)

class LYT.TextContentDocument extends LYT.DTBDocument
  resolveUrls: (resources) ->
    this.source.find("*[src]").each (index, item) =>
      item = jQuery item
      return if item.data("resolved")?
      item.attr "src", resources[item.attr("src")]?.url
      item.data "resolved", "yes" # Mark as already-processed
