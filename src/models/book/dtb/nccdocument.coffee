# Requires `/common`  
# Requires `textcontentdocument`  
# Requires `section`  

# -------------------

do ->
  
  # This class models a Daisy Navigation Control Center document
  class LYT.NCCDocument extends LYT.TextContentDocument
    constructor: (url, resources) ->
      super url, (deferred) =>
        @structure = parseStructure @source, resources
        @sections  = flattenStructure @structure
        linkSections @sections

    # The section getters below returns promises that wait for the section
    # resources to load.

    # Helper function for section getters
    # Return a promise that ensures that resources for both this object
    # and the section are loaded.
    _getSection: (getter) ->
      this.pipe (document) ->
        section.load() if section = getter(document.sections)
        section

    firstSection: -> @_getSection (sections) -> sections[0]

    getSectionByURL: (url) ->
      baseUrl = url.split('#')[0]
      @_getSection (sections) ->
        for section, index in sections
          return section if section.url is baseUrl

    # The segment getters below should not try waiting for resources to load
    # since this is the responsibility of the Section class as they are
    # sub-components of this class.

#STILL PROBLEMS HERE: not returning segments
#Possible solution in client code: document.firstSegment().done (segment) -> ...
#That should work
    firstSegment: -> 
      section = @firstSection()
      # FIXME: The pipe below shouldn't be necessary
      section.pipe (section) ->
        return section.firstSegment()
    
    getSegmentByURL: (url) ->
      id = url.split('#')[1]
      if section = @getSectionByURL(url)
        if id?
          return section.getSegmentById(id)
        else
          return section.firstSegment()
      throw 'getSegmentByURL called without any URL'
    
#    firstSegment: -> 
#      deferred = jQuery.Deferred()
#      if section = @firstSection()?
#        section.done ->
#          section.firstSegment().done ->
#            deferred.resolve section.firstSegment()
#          section.firstSegment().fail ->
#            deferred.reject()
#        section.fail ->
#          deferred.reject()
#      else
#        deferred.reject 'No section'
#      deferred.promise()

#    getSegmentByURL: (url) ->
#      id = url.split('#')[1]
#      if section = @getSectionByURL(url)
#        if id?
#          deferred = jQuery.Deferred()
#          section.done ->
#            segment = section.getSegmentById(id)
#            segment.done ->
#              deferred.resolve segment
#            segment.fail ->
#              deferred.reject 'Unable to loads egment with provided id'
#          return deferred
#        else
#          return section.firstSegment()
#      throw 'getSegmentByURL called without any URL'

    # FIXME: This method has to take loading into account
    getSegmentByOffset: (offset) ->
      if offset?
        for section in @sections
          return segment if segment = section.getSegmentByOffset(offset)
      else
        throw 'getSegmentByOffset called without an offset'

  # -------
  
  # ## Privileged
  
  # Internal helper function to parse the (flat) heading structure of an NCC document
  # into a nested collection of `NCCSection` objects
  parseStructure = (xml, resources) ->
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
        section = new LYT.Section heading, resources
        # Collect all higher-level headings into that section's `children` array,
        # and increment the `index` accordingly
        index += getConsecutive headings.slice(index+1), level+1, section.children
        # Add the section to the collector array
        collector.push section
      
      # If the loop ran to the end of the `headings` array, return the array's length
      return headings.length
    
    numberSections = (sections, prefix = "") ->
      prefix = "#{prefix}." if prefix
      for section, index in sections
        number = "#{prefix}#{index+1}"
        section.id = number
        numberSections section.children, number
    
    removeMetaSections = (sections, collector) ->
      blacklisted = (section) ->
        (return true if section[type] is value) for value, type of LYT.config.nccDocument.metaSections
        false
      
      index = sections.length
      until --index <= -1
        section = sections[index]
        if blacklisted section
          collector.unshift section
          sections.splice index, 1
        else
          removeMetaSections section.children, collector
    
    # Create an array to hold the structured data
    structure = []
    # Find all headings as a plain array
    headings  = jQuery.makeArray xml.find(":header")
    return [] if headings.length is 0
    # Find the level of the first heading (should be level 1)
    level     = parseInt headings[0].tagName.slice(1), 10
    # Get all consecutive headings of that level
    getConsecutive headings, level, structure
    
    # Send meta-information to the end of the structure
    metaSections = []
    removeMetaSections structure, metaSections         # Extract sections
    structure.push section for section in metaSections # Append to the end
    
    # Number sections
    numberSections structure
    
    return structure
  
  
  flattenStructure = (structure) ->
    flat = []
    for section in structure
      flat.push section
      flat = flat.concat flattenStructure(section.children)
    flat

  # Initializes previous and next attributes on section objects  
  linkSections = (sections) ->
    last = null
    for section in sections
      if last?
        section.previous = last
        last.next        = section

    
  


