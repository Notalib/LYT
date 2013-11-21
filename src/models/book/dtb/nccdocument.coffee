# Requires `/common`
# Requires `textcontentdocument`
# Requires `section`

# -------------------

do ->

  # This class models a Daisy Navigation Control Center document
  # FIXME: Don't carry the @sections array around. @structure should be used.
  #        At the same time, the flattenStructure procedure can be replaced by
  #        an extension of the getConsecutive procedure that does the linking
  #        handled by flattenStructure followed by linkSections.
  class LYT.NCCDocument extends LYT.TextContentDocument
    constructor: (url, book) ->
      super url, book.resources, =>
        @structure = parseStructure @source, book
        @sections  = flattenStructure @structure
        linkSections @sections
        section.nccDocument = this for section in @sections

    # The section getters below returns promises that wait for the section
    # resources to load.

    # Helper function for section getters
    # Return a promise that ensures that resources for both this object
    # and the section are loaded.
    _getSection: (getter) ->
      deferred = jQuery.Deferred()
      this.fail -> deferred.reject()
      this.done (document) ->
        if section = getter document.sections
          section.load()
          section.done -> deferred.resolve section
          section.fail -> deferred.reject()
        else
          deferred.reject()
      deferred.promise()

    firstSection: -> @_getSection (sections) -> sections[0]

    getSectionByURL: (url) =>
      baseUrl = url.split('#')[0]
      @_getSection (sections) ->
        for section, index in sections
          return section if section.url is baseUrl

    getSectionIndexById: (id) ->
      return i for section, i in @sections when section.id is id


  # -------

  # ## Privileged

  # Internal helper function to parse the (flat) heading structure of an NCC document
  # into a nested collection of `NCCSection` objects
  parseStructure = (xml, book) ->
    # Collects consecutive heading of the given level or higher in the `collector`.
    # I.e. given a level of 3, it will collect all `H3` elements until it hits an `H1`
    # element. Each higher level (i.e. `H4`) heading encountered along the way will be
    # collected recursively.
    # Returns the number of headings collected.
    # FIXME: Doesn't take changes in level with more than one into account, e.g. from h1 to h3.
    getConsecutive = (headings, level, collector) ->
      # Loop through the `headings` array
      index = 0
      while headings.length > index
        heading = headings[index]
        # Return the current index if the heading isn't the given level
        return index if heading.tagName.toLowerCase() isnt "h#{level}"
        # Create a section object
        section = new LYT.Section heading, book
        section.parent = level-1
        # Collect all higher-level headings into that section's `children` array,
        # and increment the `index` accordingly
        index += getConsecutive headings.slice(index+1), level+1, section.children
        # Add the section to the collector array
        collector.push section
        index++

      # If the loop ran to the end of the `headings` array, return the array's length
      return headings.length

    # TODO: See if we can remove this, since all sections are being addressed
    # using URLs
    numberSections = (sections, prefix = "") ->
      prefix = "#{prefix}." if prefix
      for section, index in sections
        number = "#{prefix}#{index+1}"
        section.id = number
        numberSections section.children, number

    markMetaSections = (sections) ->
      metaSectionList = LYT.config.nccDocument.metaSections

      isBlacklisted = (section) ->
        (return true if section[type] is value) for value, type of metaSectionList
        false
      for section in sections
        if isBlacklisted section
          section.metaContent = true
        if section.children.length
          markMetaSections section.children

    structure = []

    # Find all headings as a plain array
    headings  = jQuery.makeArray xml.find(":header")
    return [] if headings.length is 0

    # Find the level of the first heading (should be level 1)
    level = parseInt headings[0].tagName.slice(1), 10
    # Get all consecutive headings of that level
    getConsecutive headings, level, structure
    # Mark all meta sections so we don't play them per default
    markMetaSections structure
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
    previous = null
    for section in sections
      section.previous = previous
      previous?.next = section
      previous = section
