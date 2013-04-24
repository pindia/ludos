#!/usr/bin/python

# Script to run both the Ludos game server and a simple server to serve the test HTML

import subprocess, os

path = os.path.join(os.path.dirname(__file__), '..')

s1 = subprocess.Popen([os.path.join(path, 'bin', 'run')])
s2 = subprocess.Popen(['python', '-m', 'SimpleHTTPServer', '8001'], cwd=os.path.join(path, 'js'))

s1.wait()
s2.wait()