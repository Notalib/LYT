# This module handles Google Analytics tracking

startTime = new Date()
clickHandler = ->
  element = $(this)
  
  category = element.parents('div:jqmData(role="page")').jqmData('title')
  unless category
    log.error 'gatrack: class handler: can not track: no title for page.'
    return

  action = jQuery.trim(element.text()) or element.attr('title')
  dimensions = {}
  if session = LYT.session.getInfo()
    dimensions['Member-Id'] = session.memberId if session.memberId
    dimensions['User-Group'] = session.usergroup if session.usergroup
  for dimension in ['Book-Id', 'Book-Title', 'Member-Id']
    attrName = 'ga-' + dimension.toLowerCase()
    dimensions[dimension] = element.attr(attrName) if element.attr attrName
  events = []

  # If there is a label specified, move the text value down to the value
  # category action label value
  if element.attr 'data-ga-action'
    if action
      dimensions['Additional'] = action if action
    action = element.attr 'data-ga-action'

  unless action
    log.error 'gatrack: unable to determine action'
    return

  label = ''
  for dimension of dimensions
    label += ', ' if label.length > 0
    label += "#{dimension}: \"#{dimensions[dimension].replace '\"', ''}\""

  duration = new Date() - startTime
  if label.length == 0
    _gaq.push ['_trackEvent', category, action, duration]
  else
    _gaq.push ['_trackEvent', category, action, label, duration]

init = ->
  $('html').on 'click', '.gatrack', clickHandler
  $('.lyt-play, .lyt-pause').on 'click', clickHandler

LYT.gatrack =
  init: init
