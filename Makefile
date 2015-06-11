
build:
	coffee -c ./chrome-extension/*.coffee

auto:
	coffee -w -c .

install:
	sudo npm install -g .

# This by-passes npm's installation of dependencies (assuming you know they're
# all already installed).
executable = /usr/local/lib/node_modules/text-aid-too/server/server.coffee
fast-install:
	test -f $(executable)
	test -x $(executable)
	sudo install -v -m 0555 server/server.coffee $(executable)

# Run a test version of the server.  It uses a different port from the default
# port, so it doesn't conflict with the live server.  Note that you'll have to
# set the port and the secret below within the extension.
run-server:
	TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib coffee server/server.coffee --port 9294

# This target is probably of interest to smblott only.
pack-extension:
	$(MAKE) build
	google-chrome \
	   --pack-extension=$(PWD)/chrome-extension \
	   --pack-extension-key="$(HOME)/local/sbenv/ssh/text-aid-too.pem"
	ls -l chrome-extension.crx
	mv -v chrome-extension.crx $(HOME)/storage/google-drive/Extensions/text-aid-too.crx

.PHONY: build auto pack-extension run-server install fast-install

# pack:
# 	cd .. && \
# 	   zip -r chrome-new-tab-url.zip chrome-new-tab-url \
# 	   	-x chrome-new-tab-url/.git'*' \
# 		-x chrome-new-tab-url/'*'.coffee \
# 		-x chrome-new-tab-url/'*'.md \
# 		-x chrome-new-tab-url/Makefile
