
build:
	coffee -c ./chrome-extension/*.coffee

auto:
	coffee -w -c .

install:
	sudo npm install -g .

# Run a test version of the server.  It uses a different port from the default
# port, so it doesn't conflict with the live server.  Note that you'll have to
# set the port and the secret below within the extension.
run-server:
	TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib coffee server/server.coffee --port 9294 --markdown

help-text:
	coffee server/server.coffee -h

# This target is probably of interest to smblott only.
pack-extension:
	$(MAKE) build
	google-chrome \
	   --pack-extension=$(PWD)/chrome-extension \
	   --pack-extension-key="$(HOME)/local/sbenv/ssh/text-aid-too.pem"
	ls -l chrome-extension.crx
	mv -v chrome-extension.crx $(HOME)/storage/google-drive/Extensions/text-aid-too.crx

.PHONY: build auto pack-extension pack run-server install help-text publish

# For Chrome Store.
pack:
	$(MAKE) build
	zip -r text-aid-too.zip chrome-extension -x '*'.coffee

# For npm.
publish:
	$(MAKE) build
	npm publish
