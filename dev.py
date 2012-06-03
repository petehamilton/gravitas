#!/usr/bin/env python

commands = [
    'sh -c "cd client && python -m SimpleHTTPServer"',
    'stylus --watch client/',
]

if __name__ == '__main__':
    import runtogether
    runtogether.runtogether(commands)
