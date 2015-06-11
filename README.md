## Text-Aid-Too

This is functional (I'm using it!) but nevertheless very much a work in progress.

*Text-aid-too* is a variation on the "Text-Aid" idea.  It's a combination of a
chrome extension and a server which allows for editing web inputs in a native
editor, such as Vim or Emacs.

*Text-aid-too* is also different:
- It works for traditional HTML inputs (such as text areas), but also for
  contentEditable inputs (such as those used by GMail).
- It checks inputs dynamically, so it works on sites (such as Google's Inbox)
  which toggle the contentEditable flag dynamically.
- It updates the input's contents whenever the file is written (so, not just on
  exit).  You can preview your changes as you go along.

### Installation

Currently:
- Clone the repo.
- Install the server with `npm install -g .`.
- Run the server with `text-aid-too`.
- Build the extension with `coffee -c ./chrome-extension/*.coffee`.
- Install the server as an unpacked extension (I'll put it on the Chrome Store
  soon).  The extension is in `./chrome-extension/`.

To activate the editor, use `Ctrl-;`

### The Editor Command

Set the editor command as follows:

```Shell
text-aid-too --editor "urxvt -T textaid -geometry 100x30+80+20 -e vim"
```

### Port

The default port is `9293`.  The port to use can also be changed on the
extension's options page and for the server:

```Shell
text-aid-too --port 9293
```

### Security

By default, there's no security.  Any process on the local machine can access
the server.  To enable basic shared-secret security, set the `TEXT_AID_TOO_SECRET`
environment variable.

```Shell
TEXT_AID_TOO_SECRET=something-secret text-aid-too
```

You will then have to configure the same secret on the extension's options page.

### Caveats

There's no configuration page at the moment.  Pretty much everything is hard
wired, including the editor command. YMMV.  But check back.  Those details will be fixed soon.
