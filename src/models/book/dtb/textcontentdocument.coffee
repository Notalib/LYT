# Requires `/common`
# Requires `dtbdocument`

# -------------------

# This class models a Daisy Text Content document (an XHTML file
# containing the text of a book)

class LYT.TextContentDocument extends LYT.DTBDocument
  resolveUrls: (resources) ->
    this.source.find("*[src]").each (index, item) =>
      item = jQuery item
      return if item.data("resolved")?
      url = item.attr("src")
      url = url.substr url.lastIndexOf('/') + 1 unless url.lastIndexOf('/') == -1
      item.attr "src", resources[url]?.url
      item.data "resolved", "yes" # Mark as already-processed
