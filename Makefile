all: clean init build


staticfetcher.py:
	wget https://raw.github.com/nh2/staticfetcher/master/staticfetcher.py

.PHONY: statics_fetch statics_fetch_force statics_clean dev db server test uglify

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
	mocha --compilers coffee:coffee-script spec/*  -R spec -w


uglify:
	echo "" > client/js/ugly.js

	# uglifyjs client/js/lib/CoffeeScript.js                    >> client/js/ugly.js
	uglifyjs client/js/lib/raphael.js                         >> client/js/ugly.js
	uglifyjs client/js/lib/g.raphael.js                       >> client/js/ugly.js
	uglifyjs client/js/lib/g.pie.js                           >> client/js/ugly.js
	uglifyjs client/js/lib/g.line.js                          >> client/js/ugly.js
	uglifyjs client/js/lib/date.format.1.2.3.min.js           >> client/js/ugly.js
	uglifyjs client/js/lib/jquery.js                          >> client/js/ugly.js
	uglifyjs client/js/lib/jquery.cookie.js                   >> client/js/ugly.js
	uglifyjs client/js/lib/knockout.js                        >> client/js/ugly.js
	uglifyjs client/js/lib/sonic.js                           >> client/js/ugly.js

	coffee -p client/js/ko-extras.coffee           | uglifyjs >> client/js/ugly.js
	coffee -p client/js/config.coffee              | uglifyjs >> client/js/ugly.js
	coffee -p client/js/common/utils.coffee        | uglifyjs >> client/js/ugly.js
	coffee -p client/js/common/intersect.coffee    | uglifyjs >> client/js/ugly.js
	coffee -p client/js/crosshair.coffee           | uglifyjs >> client/js/ugly.js
	coffee -p client/js/countdown_timer.coffee     | uglifyjs >> client/js/ugly.js
	coffee -p client/js/shield_powerup_view.coffee | uglifyjs >> client/js/ugly.js
	coffee -p client/js/health_powerup_view.coffee | uglifyjs >> client/js/ugly.js
	coffee -p client/js/turret.coffee              | uglifyjs >> client/js/ugly.js
	coffee -p client/js/arena.coffee               | uglifyjs >> client/js/ugly.js
	coffee -p client/js/statistics.coffee          | uglifyjs >> client/js/ugly.js
	coffee -p client/js/game.coffee                | uglifyjs >> client/js/ugly.js
	coffee -p client/js/ball_view.coffee           | uglifyjs >> client/js/ugly.js
	coffee -p client/js/spinners.coffee            | uglifyjs >> client/js/ugly.js
	coffee -p client/main.coffee                   | uglifyjs >> client/js/ugly.js

