
secret = null

chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    unless items.key?
      chrome.storage.sync.set key: Common.default.key

chrome.storage.sync.get "secret", (items) ->
  unless chrome.runtime.lastError
    if items.secret?
      secret = items.secret
    else
      secret = "BETTER-FIX-ME-ON-THE-OPTIONS-PAGE"
      chrome.storage.sync.set { secret }

launchEdit = (request) ->
  socket = new WebSocket "ws://#{Common.default.server}/"

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
  console.log "secret", secret
  switch request.name
    when "edit"
      launchEdit request
  false
