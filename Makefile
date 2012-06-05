all: clean init build


staticfetcher.py:
	wget https://raw.github.com/nh2/staticfetcher/master/staticfetcher.py

.PHONY: statics_fetch statics_fetch_force statics_clean dev server

statics_fetch: staticfetcher.py
	python statics.py fetch

statics_fetch_force: staticfetcher.py
	python statics.py fetch --force

statics_clean: staticfetcher.py
	python statics.py clean


.PHONY: clean init build test browsertest

clean:
	(test -f staticfetcher.py && make statics_clean) || true
	rm -f staticfetcher.py

init: statics_fetch_force

dev: statics_fetch
	./dev.py

server: statics_fetch
	coffee server/server.coffee
