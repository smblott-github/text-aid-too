
build:
	coffee -c ./chrome-extension/*.coffee

auto:
	coffee -w -c .

pack-extension:
	$(MAKE) build
	google-chrome \
	   --pack-extension=$(PWD)/chrome-extension \
	   --pack-extension-key="$(HOME)/local/sbenv/ssh/text-aid-too.pem"
	ls -l chrome-extension.crx
	mv -v chrome-extension.crx $(HOME)/storage/google-drive/Extensions/text-aid-too.crx

run-server:
	TEXT_AID_TOO_SECRET=hul8quahJ4eeL1Ib coffee server/server.coffee --port 9294

.PHONY: build auto pack-extension

# pack:
# 	cd .. && \
# 	   zip -r chrome-new-tab-url.zip chrome-new-tab-url \
# 	   	-x chrome-new-tab-url/.git'*' \
# 		-x chrome-new-tab-url/'*'.coffee \
# 		-x chrome-new-tab-url/'*'.md \
# 		-x chrome-new-tab-url/Makefile
