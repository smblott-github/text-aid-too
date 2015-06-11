## Text-aid-too

This is functional (I'm using it!) but nevertheless very much a work in progress.

*Text-aid-too* is a variation on the "Text-Aid" idea.  It's a combination of a
chrome extension and a server which allows for editing web inputs in a native
editor, such as Vim.

*Text-aid-too* is also different:
- It works for traditional HTML inputs (such as text areas), but also for
  ContentEditable inputs (such as those used by GMail).
- It updates the inputs contents whenever the file is written (so, not just on
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

### Caveats

There's no configuration page at the moment.  Pretty much everything is hard
wired, including the editor command. YMMV.  But check back.  Those details will be fixed soon.
