
chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    unless items.key?
      chrome.storage.sync.set key: Common.default.key

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
  switch request.name
    when "edit"
      launchEdit request
  false
