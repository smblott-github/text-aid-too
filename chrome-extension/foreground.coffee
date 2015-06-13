
frame = 1 + Math.floor 999999999 * Math.random()

# Tests whether this text-aid-too's trigger event.
isTriggerEvent = do ->
  properties = [ "altKey", "ctrlKey", "shiftKey", "keyCode" ]

  (key, event) ->
    for property in properties
      return false unless event[property] == key[property]
    true

contentCache = {}

getElementContent = (element, id) ->
  if contentCache[id]?
    contentCache[id]
  else if element.isContentEditable
    element.innerHTML
  else
    element.value

setElementContent = (element, request) ->
  contentCache[request.id] = request.originalText if request.originalText?
  if element.isContentEditable
    element.innerHTML = request.text
  else
    element.value = request.text

clearElementContent = (event) ->
  if element = getElement()
    id = Common.identity.getId element
    delete contentCache[id] if id? and contentCache[id]?
  true

# Send a request to edit text.
editElement = (element) ->
  id = Common.identity.getId element
  chrome.runtime.sendMessage
    name: "edit"
    text: getElementContent element, id
    isContentEditable: element.isContentEditable
    id: id
    frame: frame

# Receive edited text.
chrome.runtime.onMessage.addListener (request, sender) ->
  if request.frame == frame and element = Common.identity.getObj request.id
    setElementContent element, request
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
      maintainIcon()
      if isTriggerEvent(key, event) and element = getElement()
        Common.log "keyboard hit, element:", element
        event.preventDefault()
        event.stopImmediatePropagation()
        editElement element
        return false
      true

    chrome.storage.onChanged.addListener (changes, area) =>
      if area == "sync" and changes.key?.newValue?
        key = changes.key.newValue

maintainIcon = do ->
  showing = false
  ->
    changed = false
    if not showing and getElement()
      showing = true
      changed = true
    else if showing and not getElement()
      showing = false
      changed = true
    if changed
      chrome.runtime.sendMessage name: "icon", showing: showing
      Common.log "icon:", showing
    true

for event in [ "focus", "blur" ]
  installListener window, event, maintainIcon

installListener window, "keypress", clearElementContent

