#!/usr/bin/env python

commands = [
    # 'sh -c "cd client && python -m SimpleHTTPServer"',  # Using express now
    'stylus --watch client/ -o client/gen',
    'vogue client/',
    # 'coffee --compile --watch .',  # We try to avoid using this if possible.
]

if __name__ == '__main__':
    import runtogether
    runtogether.runtogether(commands)
