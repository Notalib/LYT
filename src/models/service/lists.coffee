# Requires `catalog`  

# -------------------

# This module contains "canned" searches such as Top 10 lists

LYT.lists = do ->
  
  # Make a Top 10 list-search callback
  list = (term = "", params = {}) ->
    [term, params] = ["", term] if arguments.length is 1
    -> LYT.catalog.search term, 1, params, 10
  
  [
    { id: "list_item_1", title: "Suggestions",           callback: LYT.catalog.getSuggestions }
    { id: "list_item_2", title: "Latest books",          callback: list() }
    { id: "list_item_3", title: "Most popular",          callback: list(sort: LYT.catalog.SORTING_OPTIONS.last3month) }
    { id: "list_item_4", title: "Most popular - Kids",   callback: list("publikum=unge",   sort: LYT.catalog.SORTING_OPTIONS.last3month) }
    { id: "list_item_5", title: "Most popular - Adults", callback: list("publikum=voksne", sort: LYT.catalog.SORTING_OPTIONS.last3month) }
  ]
