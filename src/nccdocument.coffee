do ->
  
  # ## Public
  
  # Class to model an NCC document
  class LYT.NCCDocument extends LYT.TextContentDocument
    constructor: (url) ->
      super url, (deferred) =>
        @structure = parseStructure @xml
    
    findSection: (id = null) ->
      find = (id, sections) ->
        for section in sections
          if section.id is id
            return section
          else if section.children?
            child = find id, section.children
            return child if child?
        return null
      
      return @structure[0] or null unless id
      find id, @structure
      
  # -------
  
  # ## Privileged
  
  # Internal class to model a section (i.e. a heading and its
  # sub-headings) of an NCC document
  class NCCSection
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
    
  # -------
  
  # Internal helper function to parse the (flat) heading structure of an NCC document
  # into a nested collection of `NCCSection` objects
  parseStructure = (xml) ->
    # Collects consecutive heading of the given level or higher in the `collector`.  
    # I.e. given a level of 3, it will collect all `H3` elements until it hits an `H1`
    # element. Each higher level (i.e. `H4`) heading encountered along the way will be
    # collected recursively.  
    # Returns the number of headings collected.
    getConsecutive = (headings, level, collector) ->
      # Loop through the `headings` array
      for heading, index in headings
        # Return the current index if the heading isn't the given level
        return index if heading.tagName.toLowerCase() isnt "h#{level}"
        # Create a section object
        section = new NCCSection heading
        # Collect all higher-level headings into that section's `children` array,
        # and increment the `index` accordingly
        index += getConsecutive headings.slice(index+1), level+1, section.children
        # Add the section to the collector array
        collector.push section
      
      # If the loop ran to the end of the `headings` array, return the array's length
      return headings.length
    
    # Create an array to hold the structured data
    structure = []
    # Find all headings as a plain array
    headings  = jQuery.makeArray xml.find(":header")
    return [] if headings.length is 0
    # Find the level of the first heading (should be level 1)
    level     = parseInt headings[0].tagName.slice(1), 10
    # Get all consecutive headings of that level
    getConsecutive headings, level, structure
    return structure
  
