# Requires `/lyt`  

# -------------------

events = []
lastValues = {}
started = new Date()

last = -> events[events.length]

record = (eventLabel, data) ->
  event =
    label: eventLabel
    delta: new Date() - started
  unchanged = []
  changed = {}
  for key, value of data
    continue if typeof value is 'object'
    if value is lastValues[key]
      unchanged.push key
    else
      lastValues[key] = value
      changed[key]    = value
  event.unchanged = unchanged
  event.changed   = changed
  events.push event

iterateArrays = (callback) ->
  keys =
    delta: 1
    label: 1
  for event in events
    for key of event.changed
      keys[key] = 1
  keys = (key for key of keys)
  keys.push 'delta'
  keys.push 'label'
  callback keys
  currentValues = []
  for event in events
    currentValues.delta = event.delta
    currentValues.label = event.label
    for key in keys
      if event.changed[key]?
        currentValues[key] = event.changed[key]
    callback (currentValues[key] for key in keys)
  return

iterateObjects = (callback) ->
  fields = false
  lastObject = null
  iterateArrays (data) ->
    if fields
      result = {}
      for i in [0 ... fields.length]
        result[fields[i]] = data[i]
      callback result
    else
      fields = data

fieldInfo = ->
  fields = {}
  iterateObjects (object) ->
    for key, value of object
      fieldInfo = fields[key] or {}
      fields[key] = fieldInfo
      continue if fieldInfo.type is 'unknown'
      continue if typeof value is 'undefined' 
      if typeof value is 'object' or typeof value is 'function' or typeof value is 'boolean'
        fieldInfo.type = typeof value
      continue if fieldInfo.type is 'object' or fieldInfo.type is 'function' or typeof value is 'boolean'
      if typeof value is 'string'
        fieldInfo.type = typeof value
        fieldInfo.domain or= {}
        fieldInfo.domain[value] = 1
      continue if fieldInfo.type is 'string'
      if typeof value is 'number'
        fieldInfo.type = typeof value
        fieldInfo.domain or= {}
        fieldInfo.domain.max or= value
        fieldInfo.domain.min or= value
        fieldInfo.domain.max = value if fieldInfo.domain.max < value
        fieldInfo.domain.min = value if fieldInfo.domain.min > value
      continue if fieldInfo.type is 'number'
      fieldInfo.type = 'unknown'
  fields


LYT.instrumentation =
  last:           last
  record:         record
  events:         events
  iterateArrays:  iterateArrays
  iterateObjects: iterateObjects
  fieldInfo:      fieldInfo
  setEvents:      (newEvents) -> events = newEvents 
