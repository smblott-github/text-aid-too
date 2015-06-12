
frame = 1 + Math.floor 999999999 * Math.random()

# Tests whether this text-aid-too's trigger event.
isTriggerEvent = do ->
  properties = [ "altKey", "ctrlKey", "shiftKey", "keyCode" ]

  (key, event) ->
    for property in properties
      return false unless event[property] == key[property]
    true

getElementContent = (element) ->
  if element.isContentEditable then element.innerHTML else element.value

setElementContent = (element, text) ->
  if element.isContentEditable then element.innerHTML = text else element.value = text

# Send a request to edit text.
editElement = (element) ->
  chrome.runtime.sendMessage
    name: "edit"
    text: getElementContent element
    isContentEditable: element.isContentEditable
    id: Common.identity.getId element
    frame: frame

# Receive edited text.
chrome.runtime.onMessage.addListener (request, sender) ->
  if request.frame == frame and element = Common.identity.getObj request.id
    setElementContent element, request.text
  false

# Returns the active element (if it is editable) or null.
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

chrome.storage.sync.get "key", (items) ->
  unless chrome.runtime.lastError
    key = items.key

    # This is the main keyboard-event listener.  We check on every keydown because some sites (notably
    # Google's Inbox) change the content-editable flag on the fly.
    installListener window, "keydown", (event) ->
      if isTriggerEvent(key, event) and element = getElement()
        event.preventDefault()
        event.stopImmediatePropagation()
        editElement element
        return false
      true

    chrome.storage.onChanged.addListener (changes, area) =>
      if area == "sync" and changes.key?.newValue?
        key = changes.key.newValue

