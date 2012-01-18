# [Undo Wikipedia Blackout](http://neocotic.com/UndoWikipediaBlackout)  
# (c) 2012 Alasdair Mercer  
# Freely distributable under the MIT license.  
# For all details and documentation:  
# <http://neocotic.com/UndoWikipediaBlackout>

# Functionality
# -------------

# Wrap the functionality in a request for Undo Wikipedia Blackout's details in
# order to determine whether or not today is a known blackout day for
# Wikipedia.
chrome.extension.sendRequest type: 'info', (data) ->
  if data.blackout
    css = '#mw-sopaOverlay {display: none !important;}'
    ids = [
      'mw-page-base'
      'mw-head-base'
      'content'
      'mw-head'
      'mw-panel'
      'footer'
    ]
    # Attempt to hide the overlay before it even appears and ensure the core
    # known elements are not hidden by the blackout code.
    for id in ids
      element = document.getElementById id
      css    += "##{id} {display: block !important;}" if element
    element = document.createElement 'style'
    element.type = 'text/css'
    element.innerText = css
    document.head.appendChild element
    # Tell the background page to show the page action now.
    chrome.extension.sendRequest type: 'show'