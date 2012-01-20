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
    # Add CSS to ensure each identified element is displayed.
    css += "##{id} {display: block !important;}" for id in ids
    # Create style element to contain the CSS and attach it to the document.
    style = document.createElement 'style'
    style.type = 'text/css'
    style.innerText = css
    document.head.appendChild style
    # Tell the background page to show the page action now.
    chrome.extension.sendRequest type: 'show'