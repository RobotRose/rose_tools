#! /usr/bin/env python
import os
import os.path
import subprocess
import time
import sys
import socket
import argparse

# Rose B.V.
# Author: Okke Hendriks
# Date: 05-09-2014
# Rose boot script

#parser = argparse.ArgumentParser(description='Boot Rose')
#parser.add_argument('version', metavar='version', type=str,
#                   help='Which version of Rose do you want to boot?')
#arguments = parser.parse_args()
#arguments.version
path = os.path.expanduser("~/ROSE_VERSION")
version = open(path).readline().strip()
print "Booting rose{version}...".format(version=version)

getIPProc = subprocess.Popen("""ifconfig eth1 | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}'""", stdout=subprocess.PIPE, shell=True)
my_ip = getIPProc.stdout.read().strip()

# Screen sessions
os.system("""screen -t roscore -S roscore -d -m bash""")
print "Started roscore screen session."

os.system("""screen -t platform -S platform -d -m bash""")
print "Started platform screen session."

os.system("""screen -t body -S body -d -m bash""")
print "Started body screen session."

print "Sleeping 5s..."
time.sleep(5)

# Start the core
print "Starting roscore..."
roscore_proc 	= subprocess.Popen("""screen -S roscore -p 0 -X stuff 'roscore\015'""", stdout=subprocess.PIPE, shell=True)
print roscore_proc.stdout.read()
print "Sleeping 30s..."
time.sleep(30)

print "Starting platform{version}...".format(version=version)
platform_proc 	= subprocess.Popen("""screen -S platform -p 0 -X stuff 'roslaunch  ${LAUNCH_DIR}/platform.launch\015'""".format(version=version), 
                                    stdout=subprocess.PIPE, shell=True)
print roscore_proc.stdout.read()
print "Sleeping 5s..."
time.sleep(5)

print "Starting body{version}...".format(version=version)
body_proc 		= subprocess.Popen("""screen -S body -p 0 -X stuff 'roslaunch ${LAUNCH_DIR}/body.launch\015'""".format(version=version), 
                                    stdout=subprocess.PIPE, shell=True)
print roscore_proc.stdout.read()

print "All started. You can reattach to the screens with '$ screen -r roscore', '$ screen -r body', '$ screen -r platform'"

