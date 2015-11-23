do ->
  locales = {}
  activeLocale = LYT.config.locale or null

  LYT.l10n =
    get: (string) ->
      if not locales[activeLocale]?[string]
        log.warn "Couldn't find string #{string} in locale #{activeLocale}"

      locales[activeLocale]?[string] or string

    register: (localeName, dictionary) ->
      locales[localeName] = dictionary

    setLocale: (localeName) ->
      activeLocale = localeName
