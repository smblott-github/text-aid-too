
chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    unless items.key?
      chrome.storage.sync.set key: Common.default.key

getOrSet = (key, value, callback = null) ->
  chrome.storage.sync.get key, (items) ->
    unless chrome.runtime.lastError
      if items[key]?
        callback? items[key]
      else
        obj = {}
        obj[key] = value
        chrome.storage.sync.set obj
        callback? value

getOrSet "port", Common.default.port
getOrSet "secret", Common.default.secret

launchEdit = (request) ->
  getOrSet "port", Common.default.port, (port) ->
    port = parseInt port

    getOrSet "secret", Common.default.secret, (secret) ->
      request.secret = secret
      socket = new WebSocket "ws://localhost:#{port}/"
      console.log port, secret

      socket.onerror = -> socket.close()
      socket.onclose = -> socket.close()

      socket.onopen = ->
        socket.send JSON.stringify request

      socket.onmessage = (message) ->
        response = JSON.parse message.data
        chrome.tabs.sendMessage response.tabId, response

chrome.runtime.onMessage.addListener (request, sender) ->
  if sender.tab?.id?
    launchEdit Common.extend request, tabId: sender.tab.id
  false
