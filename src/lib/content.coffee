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
chrome.extension.sendRequest type: 'profiles', (data) ->
  if data.profiles.length
    # Generate CSS based on the available profiles.
    css = ''
    css += "#{profile.selector} {#{profile.css}} " for profile in data.profiles
    # Create style element to contain the CSS and attach it to the document.
    style = document.createElement 'style'
    style.type = 'text/css'
    style.innerText = css
    document.head.appendChild style
    # Tell the background page to show the page action now.
    chrome.extension.sendRequest type: 'show'