
key = null
frame = 1 + Math.floor 999999999 * Math.random()

chrome.storage.sync.get "key", (items) ->
  key = items.key
  console.log key

isTriggerEvent = do ->
  properties = [ "altKey", "ctrlKey", "shiftKey", "keyCode" ]

  (event) ->
    for property in properties
      return false unless key? and event[property] == key[property]
    true

getElementContent = (element) ->
  if element.isContentEditable then element.innerHTML else element.value

setElementContent = (element, text) ->
  if element.isContentEditable then element.innerHTML = text else element.value = text

editElement = (element) ->
  chrome.runtime.sendMessage
    name: "edit"
    text: getElementContent element
    isContentEditable: element.isContentEditable
    id: Common.identity.getId element
    frame: frame

chrome.runtime.onMessage.addListener (request, sender) ->
  return false unless request.frame == frame
  element = Common.identity.getObj request.id
  setElementContent element, request.text
  false

getElement = do ->
  nonEditableInputs = [ "radio", "checkbox" ]
  editableNodeNames = [ "textarea" ]

  (element = document.activeElement) ->
    nodeName = element.nodeName?.toLowerCase()
    return element if false or
      element.isContentEditable or
      (nodeName? and nodeName == "input" and element.type not in nonEditableInputs) or
      (nodeName? and nodeName in editableNodeNames)
    null

installListener = (element, event, callback) ->
  element.addEventListener event, callback, true

installListener window, "keydown", (event) ->
  return true unless isTriggerEvent event
  return true unless element = getElement()
  event.preventDefault()
  event.stopImmediatePropagation()
  editElement element
  false
