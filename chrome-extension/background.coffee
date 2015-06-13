
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
      Common.log "send: #{request.tabId} #{request.id} #{url} #{secret} length=#{request.text.length}"

      socket = new WebSocket url
      socket.onerror = socket.onclose = ->
        Common.log "  done: #{request.tabId} #{request.id} #{url} #{secret}"
        socket.close()

      socket.onopen = ->
        socket.send JSON.stringify request

      socket.onmessage = (message) ->
        response = JSON.parse message.data
        Common.log "  recv: #{request.tabId} #{request.id} #{url} #{secret} length=#{response.text.length}"
        chrome.tabs.sendMessage response.tabId, response

chrome.runtime.onMessage.addListener (request, sender) ->
  Common.log "launching..."
  if sender.tab?.id?
    launchEdit Common.extend request,
      tabId: sender.tab.id
      url: sender.tab.url
      isChromeStoreVersion: Common.isChromeStoreVersion
  false
