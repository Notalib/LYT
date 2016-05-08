# Requires `/common`

# This class represents a bookmark in a book - either set explicit by user
# or as a lastmark.
#
# Caveat emptor: Since a bookmark refers to a SMIL par (or seq) element,
# the attribute timeOffset is a SMIL offset, not an audio offset.

class LYT.Bookmark
  constructor: (data) ->
    @[key] = data[key] for key in ['note', 'URI', 'timeOffset', 'ncxRef', 'label']
