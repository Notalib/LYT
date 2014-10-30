# Requires `/common`
# Requires `dtbdocument`

# -------------------

# This class models a Daisy Text Content document (an XHTML file
# containing the text of a book)

class LYT.TextContentDocument extends LYT.DTBDocument

  # Private method for resolving URLs
  resolveURLs = (source, resources, isCartoon) ->
    # Resolve images
    source.find("*[data-src]").each (index, item) ->
      item = jQuery item
      return if item.data("resolved")?
      url = item.attr("data-src").replace( /^\//, '' )
      new_url = resources[url]?.url
      item.data "resolved", "yes" # Mark as processed
      if isCartoon
        item.attr 'src', new_url
        item.removeAttr 'data-src'
      else
        item.attr 'data-src', new_url
        item.addClass 'loader-icon'

  constructor: (url, resources, callback) ->
    super url, =>
      resolveURLs @source, resources, @isCartoon()
      callback() if typeof callback is "function"

  isCartoon: () ->
    return @_isCartoon unless typeof @_isCartoon is 'undefined'

    pages = @source.find('.page').toArray()
    @_isCartoon = pages.length != 0 && pages.every (page) -> $(page).children('img').length == 1

