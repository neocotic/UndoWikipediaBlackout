# [Undo Wikipedia Blackout](http://neocotic.com/UndoWikipediaBlackout)  
# (c) 2012 Alasdair Mercer  
# Freely distributable under the MIT license.  
# For all details and documentation:  
# <http://neocotic.com/UndoWikipediaBlackout>

# Private constants
# -----------------

# Date ranges for known blackouts on Wikipedia.
BLACKOUTS        = [
  start: new Date 2012, 0, 17, 0,  0,  0,  0
  end:   new Date 2012, 0, 19, 23, 59, 59, 999
]
# Extension ID being used by Undo Wikipedia Blackout.
EXTENSION_ID     = utils.i18n '@@extension_id'
# Domain of Undo Wikipedia Blackout's homepage.
HOMEPAGE_DOMAIN  = 'neocotic.com'
# Domain of Wikipedia.
WIKIPEDIA_DOMAIN = 'wikipedia.org'

# Private variables
# -----------------

# Current version of Undo Wikipedia Blackout.
version = ''

# Private functions
# -----------------

# Inject and execute the content scripts within all of the tabs (where
# appropriate) of each Chrome window.
executeScriptsInExistingWindows = ->
  chrome.windows.getAll null, (windows) ->
    for win in windows
      # Retrieve all tabs open in `win`.
      chrome.tabs.query windowId: win.id, (tabs) ->
        for tab in tabs
          # Only execute blackout removal content scripts for tabs displaying a
          # page on Wikipedia's domain.
          if tab.url.indexOf(WIKIPEDIA_DOMAIN) isnt -1
            chrome.tabs.executeScript tab.id, file: 'lib/content.js'
          # Only execute inline installation content script for tabs displaying
          # a page on Undo Wikipedia Blackout's homepage domain.
          if tab.url.indexOf(HOMEPAGE_DOMAIN) isnt -1
            chrome.tabs.executeScript tab.id, file: 'lib/install.js'

# Determine whether or not today falls within a known blackout for Wikipedia.
isBlackoutToday = ->
  today = new Date()
  return yes for range in BLACKOUTS when range.start <= today <= range.end
  no

# Listener for internal requests to Undo Wikipedia Blackout.
onRequest = (request, sender, sendResponse) ->
  switch request?.type
    # Send some useful information back to the sender.
    when 'info'
      sendResponse?(
        blackout: isBlackoutToday()
        id:       EXTENSION_ID
        version:  version
      )
    # Show the page action if the request originated from a content script.
    when 'show' then chrome.pageAction.show sender.tab.id if sender.tab

# Background page setup
# ---------------------

ext = window.ext =

  # Public functions
  # ----------------

  # Initialize the background page.  
  # This will involve initializing the settings and adding the request
  # listeners.
  init: ->
    utils.init 'log', off
    # Add listeners for internal requests.
    chrome.extension.onRequest.addListener onRequest
    # It's nice knowing what version is running.
    req = new XMLHttpRequest()
    req.open 'GET', chrome.extension.getURL('manifest.json'), yes
    req.onreadystatechange = ->
      if req.readyState is 4
        data    = JSON.parse req.responseText
        version = data.version
        # Execute content scripts now that we know the version.
        executeScriptsInExistingWindows()
    req.send()