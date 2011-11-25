class LYT.Section
  constructor: (heading) ->
    # Wrap the heading in a jQuery object
    heading = jQuery heading
    # Get the basic attributes
    @id    = heading.attr "id"
    @class = heading.attr "class"
    # Get the anchor element of the heading, and its attributes
    anchor = heading.find("a:first")
    @title = jQuery.trim anchor.text()
    @url   = anchor.attr "href"
    # Create an array to collect any sub-headings
    @children = []
  
  
  # Flattens the structure from this section and "downwards"
  flatten: ->
    flat = [this]
    flat = flat.concat child.flatten() for child in @children
    flat