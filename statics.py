#!/usr/bin/env python


ROOT_DIR = 'client'

STATICS = {
	'js/lib/jasmine.js': 'https://raw.github.com/pivotal/jasmine/master/lib/jasmine-core/jasmine.js',
	'js/lib/jasmine-html.js': 'https://raw.github.com/pivotal/jasmine/master/lib/jasmine-core/jasmine-html.js',
	'css/lib/jasmine.css': 'https://raw.github.com/pivotal/jasmine/master/lib/jasmine-core/jasmine.css',

	'js/lib/coffee-script.js': 'https://raw.github.com/jashkenas/coffee-script/master/extras/coffee-script.js',

	# TODO Get this from upstream once merged (https://github.com/jcarver989/phantom-jasmine/pull/1)
	'js/lib/console-runner.js': 'https://raw.github.com/nh2/phantom-jasmine/fix-long-running-tests/lib/console-runner.js',
	'js/lib/run_jasmine_test.coffee': 'https://raw.github.com/nh2/phantom-jasmine/fix-long-running-tests/lib/run_jasmine_test.coffee',

	'js/lib/knockout.js': 'http://cloud.github.com/downloads/SteveSanderson/knockout/knockout-2.1.0.js',
	'js/lib/knockout.mapping.js': 'https://raw.github.com/SteveSanderson/knockout.mapping/master/build/output/knockout.mapping-latest.js',

	# 'lib/jsschema.js': 'https://raw.github.com/nh2/jsschema/schemafields/jsschema.js',
	# 'runtogether.py': 'https://raw.github.com/nh2/runtogether/master/runtogether.py',

	'js/lib/jquery.js': 'http://code.jquery.com/jquery.min.js',
	'js/lib/jquery.cookie.js': 'https://raw.github.com/carhartl/jquery-cookie/master/jquery.cookie.js',

	# Raphael for simple graphics amnipulation
	'js/lib/raphael.js': 'http://github.com/DmitryBaranovskiy/raphael/raw/master/raphael.js',
}


if __name__ == '__main__':
	import staticfetcher
	staticfetcher.Staticfetcher(STATICS, ROOT_DIR).run()
