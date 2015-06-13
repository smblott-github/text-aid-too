
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
  Common.log request

  getOrSet "port", Common.default.port, (port) ->
    port = parseInt port
    url = "ws://localhost:#{port}/"

    getOrSet "secret", Common.default.secret, (secret) ->
      request.secret = secret
      Common.log "send: #{request.tabId} #{request.id} #{url} #{secret} length=#{request.text?.length}"

      socket = new WebSocket url
      socket.onerror = socket.onclose = ->
        Common.log "  done: #{request.tabId} #{request.id} #{url} #{secret}"
        socket.close()

      socket.onopen = ->
        socket.send JSON.stringify request

      socket.onmessage = (message) ->
        response = JSON.parse message.data
        Common.log "  recv: #{request.tabId} #{request.id} #{url} #{secret} length=#{response.text?.length}"
        chrome.tabs.sendMessage response.tabId, response
  false # We will not be calling sendResponse.

launchPing = (request, sender, sendResponse) ->
  getOrSet "port", Common.default.port, (port) ->
    port = parseInt port
    url = "ws://localhost:#{port}/"

    getOrSet "secret", Common.default.secret, (secret) ->
      request.secret = secret
      Common.log "ping..."

      exit = (isUp) ->
        socket.onerror = socket.onclose = socket.onmessage = null
        Common.log "  #{isUp}"
        sendResponse { isUp }
        socket.close()

      socket = new WebSocket url
      socket.onerror = socket.onclose = -> exit false
      socket.onopen = -> socket.send JSON.stringify request

      socket.onmessage = (message) ->
        response = JSON.parse message.data
        exit response.isOk

  true # We *will* be calling sendResponse.

updateIcon = (request, sender) ->
  Common.log "icon", request.showing
  if request.showing
    chrome.pageAction.show sender.tab.id
  else
    chrome.pageAction.hide sender.tab.id
  false # We will not be calling sendResponse.

handlers =
  edit: launchEdit
  ping: launchPing
  icon: updateIcon

chrome.runtime.onMessage.addListener (request, sender, sendResponse) ->
  Common.log "request", request.name, handlers[request.name]?
  if sender.tab?.id?
    Common.extend request,
      tabId: sender.tab.id
      url: sender.tab.url
      isChromeStoreVersion: Common.isChromeStoreVersion
    handlers[request.name]? request, sender, sendResponse
  else
    false
