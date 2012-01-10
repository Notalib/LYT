# This module contains "canned" searches such as Top 10 lists

LYT.lists = do ->
  
  # Make a Top 10 list-search callback
  list = (term = "", params = {}) ->
    [term, params] = ["", term] if arguments.length is 1
    -> LYT.catalog.search term, 1, params, 10
  
  [
    { title: "Latest books",          callback: list() }
    { title: "Most popular",          callback: list(sort: LYT.catalog.SORTING_OPTIONS.last3month) }
    { title: "Most popular - Kids",   callback: list("publikum=unge",   sort: LYT.catalog.SORTING_OPTIONS.last3month) }
    { title: "Most popular - Adults", callback: list("publikum=voksne", sort: LYT.catalog.SORTING_OPTIONS.last3month) }
  ]
