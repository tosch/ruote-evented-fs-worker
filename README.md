Ruote::EventedFsWorker
======================

This is an evented worker for [ruote's](http://ruote.rubyforge.org/) file
system storage.

It uses [EventMachine](http://eventmachine.rubyforge.org/) and
[em-dir-watcher](https://github.com/mockko/em-dir-watcher) under the hood.


Installation/Usage
------------------

Sorry, it's quite complicated at the moment as we're relying on ruote 2.3.0
which isn't released yet. For now, clone the source and have a look at
examples/test.rb. Don't forget to run bundle.

If you're not using Linux, you'll have to modify the gemspec to not have
rb-inotify as dependency. See
[em-dir-watcher's documentation](https://github.com/mockko/em-dir-watcher)
for the gems you need to install on your system.


Known issues
------------

Ruote's #wait_for method doesn't work with Ruote::EventedFsWorker.


License
-------

[Same as ruote's](https://raw.github.com/jmettraux/ruote/master/LICENSE.txt),
but copyright is (c) 2012 Torsten Schönebaum.
