all: clean init build


staticfetcher.py:
	wget https://raw.github.com/nh2/staticfetcher/master/staticfetcher.py

.PHONY: statics_fetch statics_fetch_force statics_clean dev db server test

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

db:
	coffee server/db-setup.coffee

server: statics_fetch
	coffee server/server.coffee

test:
	@echo "See ../client/test.html for browser tests"
	mocha --compilers coffee:coffee-script server/test.coffee
	mocha --compilers coffee:coffee-script common/
	mocha --compilers coffee:coffee-script server/testTriangles.coffee
	mocha --compilers coffee:coffee-script server/testPlayerFunctionality.coffee
