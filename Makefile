
auto:
	coffee -w -c .

# build:
# 	coffee -c *.coffee

pack:
	cd .. && \
	   zip -r chrome-new-tab-url.zip chrome-new-tab-url \
	   	-x chrome-new-tab-url/.git'*' \
		-x chrome-new-tab-url/'*'.coffee \
		-x chrome-new-tab-url/'*'.md \
		-x chrome-new-tab-url/Makefile
