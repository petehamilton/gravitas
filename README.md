Building
--------

Use the toplevel makefile. Have a look at the targets.

There also a staticfetcher called by the Makefile that allows pulling in external resources (e.g. jQuery). They are defined in `statics.py`. Don't add the fetched files to Git!


Code Review
-----------

Let's do semi-proper code review: Everyone can just commit, but make sure every commit is reviewed by somebody else shortly after.


Testing
-------

Make sure you know how to write jasmine tests. Commit the tests with the code.


Links
-----

* [Jasmine](https://github.com/pivotal/jasmine/wiki) for testing. Especially [Matchers](https://github.com/pivotal/jasmine/wiki/Matchers) and [Suites and Specs](https://github.com/pivotal/jasmine/wiki/Suites-and-specs)
* [CoffeeScript](http://js2coffee.org) and [js2coffee](http://js2coffee.org)
* [git ready](http://gitready.com)

Installing on OS X
------------------
* [homebrew] (https://github.com/mxcl/homebrew)
* run ```brew install node```
* run ```brew install wget```
* run ```make```
* run ```curl http://npmjs.org/install.sh | sh```
* run ```npm install -g coffee-script```