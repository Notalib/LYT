# Requires `catalog`  

# -------------------

# This module contains "canned" searches such as Top 10 lists

list = (term = "", params = {}) ->
  [term, params] = ["", term] if arguments.length is 1
  -> LYT.catalog.search term, 1, params, 10

LYT.predefinedSearches = 
  anbefalinger:
    hash: "search"
    param: "list"
    title: "Suggestions"
    callback: LYT.catalog.getSuggestions
  nye:
    hash: "search"
    param: "list"
    title: "Latest books"
    callback: list("!genre=undervejs", sort: LYT.catalog.SORTING_OPTIONS.new)
  tegneserie:
    hash: "search"
    param: "list"
    title: "Comics"
    callback: list("genre=tegneserie", sort: LYT.catalog.SORTING_OPTIONS.new)
  top:
    hash: "search"
    param: "list"
    title: "Most popular"
    callback: list("", sort: LYT.catalog.SORTING_OPTIONS.last3month)
  topung:
    hash: "search"
    param: "list"
    title: "Most popular - Kids"
    callback: list("publikum=unge",   sort: LYT.catalog.SORTING_OPTIONS.last3month)
  topvoksen:
    hash: "search"
    param: "list"
    title: "Most popular - Adults"
    callback: list("publikum=voksne", sort: LYT.catalog.SORTING_OPTIONS.last3month)
  kommersnart:
    hash: "search"
    param: "list"
    title: "Coming"
    callback: list("genre=undervejs", sort: LYT.catalog.SORTING_OPTIONS.new)
