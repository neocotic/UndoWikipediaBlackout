# [Undo Wikipedia Blackout](http://neocotic.com/UndoWikipediaBlackout)  
# (c) 2012 Alasdair Mercer  
# Freely distributable under the MIT license.  
# For all details and documentation:  
# <http://neocotic.com/UndoWikipediaBlackout>

# Private constants
# -----------------

# Source URL of the user feedback widget script.
WIDGET_SOURCE = 'https://widget.uservoice.com/66hVxrEWDUgjuAmIIqPKg.js'

# Private variables
# -----------------

# Indicate whether or not the user feedback feature has been added to the page.
feedbackAdded = no

# Load functions
# --------------

# Bind an event of the specified `type` to the elements included by
# `selector` that, when triggered, modifies the underlying `option` with the
# value returned by `evaluate`.
bindSaveEvent = (selector, type, option, evaluate, callback) ->
  log.trace()
  $(selector).on type, ->
    $this = $ this
    key   = ''
    value = null
    store.modify option, (data) ->
      key = $this.attr('id').match(new RegExp("^#{option}(\\S*)"))[1]
      key = key[0].toLowerCase() + key.substr 1
      data[key] = value = evaluate.call $this, key
    callback? $this, key, value

# Update the options page with the values from the current settings.
load = ->
  log.trace()
  $('#analytics').attr 'checked', 'checked' if store.get 'analytics'
  loadSaveEvents()
  loadDeveloperTools()

# Update the developer tools section of the options page with the current
# settings.
loadDeveloperTools = ->
  log.trace()
  loadLogger()

# Update the logging section of the options page with the current settings.
loadLogger = ->
  log.trace()
  logger = store.get 'logger'
  $('#loggerEnabled').attr 'checked', 'checked' if logger.enabled
  loggerLevel = $ '#loggerLevel'
  loggerLevel.find('option').remove()
  for level in log.LEVELS
    option = $ '<option/>',
      text:  i18n.get "opt_logger_level_#{level.name}_text"
      value: level.value
    option.attr 'selected', 'selected' if level.value is logger.level
    loggerLevel.append option
  # Ensure debug level is selected if configuration currently matches none.
  unless loggerLevel.find('option[selected]').length
    loggerLevel.find("option[value='#{log.DEBUG}']").attr 'selected',
      'selected'
  loadLoggerSaveEvents()

# Bind the event handlers required for persisting logging changes.
loadLoggerSaveEvents = ->
  log.trace()
  bindSaveEvent '#loggerEnabled, #loggerLevel', 'change', 'logger', (key) ->
    value = if key is 'level' then @val() else @is ':checked'
    log.debug "Changing logging #{key} to '#{value}'"
    value
  , (jel, key, value) ->
    logger = store.get 'logger'
    chrome.extension.getBackgroundPage().log.config = log.config = logger
    analytics.track 'Logging', 'Changed', key[0].toUpperCase() + key.substr(1),
      Number value

# Bind the event handlers required for persisting general changes.
loadSaveEvents = ->
  log.trace()
  $('#analytics').change ->
    enabled = $(this).is ':checked'
    log.debug "Changing analytics to '#{enabled}'"
    if enabled
      store.set 'analytics', yes
      chrome.extension.getBackgroundPage().analytics.add()
      analytics.add()
      analytics.track 'General', 'Changed', 'Analytics', 1
    else
      analytics.track 'General', 'Changed', 'Analytics', 0
      analytics.remove()
      chrome.extension.getBackgroundPage().analytics.remove()
      store.set 'analytics', no

# Miscellaneous functions
# -----------------------

# Add the user feedback feature to the page.
feedback = ->
  unless feedbackAdded
    # Temporary workaround for Content Security Policy issues with UserVoice's
    # use of inline JavaScript.  
    # This should be removed if/when it's no longer required.
    uvwDialogClose = $ '#uvw-dialog-close[onclick]'
    uvwDialogClose.live 'hover', ->
      $(this).removeAttr 'onclick'
      uvwDialogClose.die 'hover'
    $(uvwDialogClose.selector.replace('[onclick]', '')).live 'click', (e) ->
      UserVoice.hidePopupWidget()
      e.preventDefault()
    uvTabLabel = $ '#uvTabLabel[href^="javascript:"]'
    uvTabLabel.live 'hover', ->
      $(this).removeAttr 'href'
      uvTabLabel.die 'hover'
    # Continue with normal process of loading Widget.
    window.uvOptions = {}
    uv = document.createElement 'script'
    uv.async = 'async'
    uv.src   = WIDGET_SOURCE
    script = document.getElementsByTagName('script')[0]
    script.parentNode.insertBefore uv, script
    feedbackAdded = yes

# Options page setup
# ------------------

options = window.options = new class Options extends utils.Class

  # Public functions
  # ----------------

  # Initialize the options page.  
  # This will involve inserting and configuring the UI elements as well as
  # loading the current settings.
  init: ->
    log.trace()
    log.info 'Initializing the options page'
    # Add support for analytics if the user hasn't opted out.
    analytics.add() if store.get 'analytics'
    # Add the user feedback feature to the page.
    feedback()
    # Begin initialization.
    i18n.init()
    $('.year-repl').html "#{new Date().getFullYear()}"
    # Bind tab selection event to all tabs.
    initialTabChange = yes
    $('a[tabify]').click ->
      target  = $(this).attr 'tabify'
      nav     = $ "#navigation a[tabify='#{target}']"
      parent  = nav.parent 'li'
      unless parent.hasClass 'active'
        parent.siblings().removeClass 'active'
        parent.addClass 'active'
        $(target).show().siblings('.tab').hide()
        store.set 'options_active_tab', id = nav.attr 'id'
        unless initialTabChange
          id = id.match(/(\S*)_nav$/)[1]
          id = id[0].toUpperCase() + id.substr 1
          log.debug "Changing tab to #{id}"
          analytics.track 'Tabs', 'Changed', id
        initialTabChange = no
        $(document.body).scrollTop 0
    # Reflect the persisted tab.
    store.init 'options_active_tab', 'general_nav'
    optionsActiveTab = store.get 'options_active_tab'
    $("##{optionsActiveTab}").click()
    log.debug "Initially displaying tab for #{optionsActiveTab}"
    # Bind Developer Tools wizard events to their corresponding elements.
    $('#tools_nav').click -> $('#tools_wizard').modal 'show'
    $('.tools_close_btn').click -> $('#tools_wizard').modal 'hide'
    # Ensure that form submissions don't reload the page.
    $('form').submit -> no
    # Load the current option values.
    load()
    # Initialize all popovers, tooltips and *go-to* links.
    $('[popover]').each ->
      $this   = $ this
      trigger = $this.attr 'data-trigger'
      trigger = if trigger? then trigger.trim().toLowerCase() else 'hover'
      $this.popover
        content: -> i18n.get $this.attr 'popover'
        trigger: trigger
      if trigger is 'manual'
        $this.click -> $this.popover 'toggle'
    $('[title]').each ->
      $this     = $ this
      placement = $this.attr 'data-placement'
      placement = if placement? then placement.trim().toLowerCase() else 'top'
      $this.tooltip placement: placement
    $('[data-goto]').click ->
      goto = $ $(this).attr 'data-goto'
      log.debug "Relocating view to include '#{goto.selector}'"
      $(window).scrollTop goto.position()?.top or 0

# Initialize `options` when the DOM is ready.
utils.ready -> options.init()