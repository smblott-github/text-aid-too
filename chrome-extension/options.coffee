
$ = (id) -> document.getElementById id

document.addEventListener "DOMContentLoaded", ->
  portElement = $("port")
  secretElement = $("secret")

  chrome.storage.sync.get [ "port", "secret" ], (items) ->
    unless chrome.runtime.lastError
      port.value = items.port if items.port?
      secret.value = items.secret if items.secret?

      for element in [ portElement, secretElement ]
        do (element) ->
          element.addEventListener "change", ->
            obj = {}
            obj[element.id] = element.value.trim()
            chrome.storage.sync.set obj

          element.addEventListener "keydown", (event) ->
            element.blur() if event.keyCode == 27

