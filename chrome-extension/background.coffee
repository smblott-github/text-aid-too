
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

for key in [ "key", "port", "secret" ]
  getOrSet key, Common.default[key]

launchEdit = (request) ->
  getOrSet "port", Common.default.port, (port) ->
    port = parseInt port

    getOrSet "secret", Common.default.secret, (secret) ->
      request.secret = secret
      console.log port, secret

      socket = new WebSocket "ws://localhost:#{port}/"
      socket.onerror = socket.onclose = -> socket.close()

      socket.onopen = ->
        socket.send JSON.stringify request

      socket.onmessage = (message) ->
        response = JSON.parse message.data
        chrome.tabs.sendMessage response.tabId, response

chrome.runtime.onMessage.addListener (request, sender) ->
  if sender.tab?.id?
    launchEdit Common.extend request, tabId: sender.tab.id
  false
