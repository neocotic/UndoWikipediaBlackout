# [Undo Wikipedia Blackout](http://neocotic.com/UndoWikipediaBlackout)  
# (c) 2012 Alasdair Mercer  
# Freely distributable under the MIT license.  
# For all details and documentation:  
# <http://neocotic.com/UndoWikipediaBlackout>

# Private constants
# -----------------

# Date ranges for known blackouts on Wikipedia.
BLACKOUTS         = [
  date:     new Date 2012, 0, 18
  duration: 1
  profiles: [
    selector: '#mw-sopaOverlay'
    css:      'display: none !important;'
  ,
    selector: '#' + [
      'mw-page-base', 'mw-head-base', 'content'
      'mw-head',      'mw-panel',     'footer'
    ].join ', #'
    css:      'display: block !important;'
  ]
]
# Extension ID being used by Undo Wikipedia Blackout.
EXTENSION_ID      = i18n.get '@@extension_id'
# Domain of this extension's homepage.
HOMEPAGE_DOMAIN   = 'neocotic.com'
# Extension ID of the production version of Undo Wikipedia Blackout.
REAL_EXTENSION_ID = 'gbgogigdaibinioohdhejplmajgkkfdn'
# Domain of Wikipedia.
WIKIPEDIA_DOMAIN  = 'wikipedia.org'

# Private variables
# -----------------

# Indicate whether or not Undo Wikipedia Blackout has just been installed.
isNewInstall      = no
# Indicate whether or not Undo Wikipedia Blackout is currently running the
# production build.
isProductionBuild = EXTENSION_ID is REAL_EXTENSION_ID
# Current version of Undo Wikipedia Blackout.
version           = ''

# Private functions
# -----------------

# Creates start and end dates for `date`.
createRange = (date, offset = 1) ->
  log.trace()
  range =
    start: new Date date
    end:   new Date date
  range.start.setDate range.start.getDate() - offset
  range.start.setHours 0, 0, 0, 0
  range.end.setDate range.end.getDate() + offset
  range.start.setHours 23, 59, 59, 999
  range

# Inject and execute the `content.coffee` and `install.coffee` scripts within
# all of the tabs (where valid) of each Chrome window.
executeScriptsInExistingWindows = ->
  log.trace()
  # Create a runner to help manage the asynchronous aspect.
  runner = new utils.Runner()
  runner.push chrome.windows, 'getAll', null, (windows) ->
    log.info 'Retrieved the following windows...', windows
    for win in windows
      do (win) -> runner.push chrome.tabs, 'query', windowId: win.id, (tabs) ->
        log.info 'Retrieved the following tabs...', tabs
        for tab in tabs
          # Only execute blackout removal content scripts for tabs displaying a
          # page on Wikipedia's domain.
          if tab.url.indexOf(WIKIPEDIA_DOMAIN) isnt -1
            chrome.tabs.executeScript tab.id, file: 'lib/content.js'
          # Only execute inline installation content script for tabs displaying
          # a page on Undo Wikipedia Blackout's homepage domain.
          if tab.url.indexOf(HOMEPAGE_DOMAIN) isnt -1
            chrome.tabs.executeScript tab.id, file: 'lib/install.js'
        runner.next()
    runner.next()
  runner.run()

# Retrieve the profiles of all known active blackouts for Wikipedia.
getBlackoutProfiles = ->
  log.trace()
  profiles = []
  today    = new Date()
  for info in BLACKOUTS
    range = createRange info.date, info.duration
    profiles.push info.profiles... if range.start <= today <= range.end
  profiles

# Listener for internal requests to the extension.
onRequest = (request, sender, sendResponse) ->
  log.trace()
  switch request?.type
    # Send some useful information back to the sender.
    when 'info' then sendResponse? id: EXTENSION_ID, version: version
    # Send the profiles for any known active blackouts.
    when 'profiles' then sendResponse? profiles: getBlackoutProfiles()
    # Show the page action if the request originated from a content script.
    when 'show'
      if sender.tab
        chrome.pageAction.show sender.tab.id
        analytics.track 'Requests', 'Processed', 'Show'

# Initialization functions
# ------------------------

# Handle the conversion/removal of older version of settings that may have been
# stored previously by `ext.init`.
init_update = ->
  log.trace()
  # Create updater for the `settings` namespace.
  updater      = new store.Updater 'settings'
  isNewInstall = updater.isNew
  # Define the processes for all required updates to the `settings` namespace.
  updater.update '1.1.0', ->
    log.info 'Updating general settings for 1.1.0'
    store.remove 'log'

# Background page setup
# ---------------------

ext = window.ext = new class Extension extends utils.Class

  # Public functions
  # ----------------

  # Initialize the background page.  
  # This will involve initializing the settings and adding the request
  # listeners.
  init: ->
    log.trace()
    log.info 'Initializing extension controller'
    analytics.add() if store.get 'analytics'
    # Begin initialization.
    init_update()
    # Add listener for internal requests.
    chrome.extension.onRequest.addListener onRequest
    # It's nice knowing what version is running.
    req = new XMLHttpRequest()
    req.open 'GET', chrome.extension.getURL('manifest.json'), yes
    req.onreadystatechange = ->
      if req.readyState is 4
        version = JSON.parse(req.responseText).version
        if isNewInstall
          analytics.track 'Installs', 'New', version, Number isProductionBuild
        # Execute content scripts now that we know the version.
        executeScriptsInExistingWindows()
    req.send()