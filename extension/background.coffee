
chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    unless items.key?
      chrome.storage.sync.set key: Common.default.key

launchEdit = (request) ->
  request.text = "hello"
  chrome.tabs.sendMessage request.tabId, request

chrome.runtime.onMessage.addListener (request, sender) ->
  return unless sender.tab?.id?
  request.tabId = sender.tab.id
  switch request.name
    when "edit"
      launchEdit request
  false
