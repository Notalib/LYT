# Requires `/lyt`  

# -------------------

# This module contains localized strings  
# (Note: OK, so it's not really i18n-like, since it's
# just a dictionary, but "i18n" is short and sweet)

LYT.i18n = do ->
  
  # The strings themselves, as a hash
  strings =
    "Loading":                  "Indlæser"
    "Loading sound":            "Henter lyd"
    "Logging in":               "Logger ind"
    "Loading bookshelf":        "Indlæser boghylde"
    "Adding book to bookshelf": "Tilføjer bog til boghylde"
    "Loading index":            "Indlæser indholdsfortegnelse"
    "Searching":                "Søger"
    "Loading book":             "Indlæser bog"
    "Suggestions":              "Nota anbefaler"
    "Latest books":             "Nyeste bøger"
    "Most popular":             "Top 10 bøger"
    "Most popular - Kids":      "Top 10 - børn & unge"
    "Most popular - Adults":    "Top 10 - voksne"
  
  # The i18n function. Returns either the "translated"
  # string, or - if no translation was found - the
  # input string.
  (string) -> strings[string] or string

