
port = null
secret = null

chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    unless items.key?
      chrome.storage.sync.set key: Common.default.key

getOrSet = (key, value, callback) ->
  chrome.storage.sync.get key, (items) ->
    unless chrome.runtime.lastError
      if items[key]?
        callback items[key]
      else
        obj = {}
        obj[key] = value
        chrome.storage.sync.set obj
        callback value

getOrSet "port", "9293", (value) -> port = parseInt value
getOrSet "secret", "BETTER-FIX-ME-ON-THE-OPTIONS-PAGE", (value) -> secret = value

launchEdit = (request) ->
  socket = new WebSocket "ws://localhost:#{port}/"

  socket.onerror = -> socket.close()
  socket.onclose = -> socket.close()

  socket.onopen = ->
    socket.send JSON.stringify request

  socket.onmessage = (message) ->
    response = JSON.parse message.data
    chrome.tabs.sendMessage response.tabId, response

chrome.runtime.onMessage.addListener (request, sender) ->
  return unless sender.tab?.id?
  request.tabId = sender.tab.id
  request.secret = secret
  switch request.name
    when "edit"
      launchEdit request
  false
