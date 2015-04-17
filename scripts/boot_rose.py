#! /usr/bin/env python
import os
import os.path
import subprocess
import time
import sys
import socket
import argparse
import subprocess as sp

# Rose B.V.
# Author: Okke Hendriks
# Date: 05-09-2014
# Rose boot script

def check_ping(hostname):
    response = os.system("ping -c 1 -i 1 -w 1 " + hostname)
    if response == 0:
        return True
    else:
        return False

print "Booting rose..."

getIPProc = subprocess.Popen("""ifconfig eth1 | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}'""", stdout=subprocess.PIPE, shell=True)
my_ip = getIPProc.stdout.read().strip()

# Screen sessions
os.system("""screen -t roscore -S roscore -d -m bash""")
print "Started roscore screen session."

os.system("""screen -t platform -S platform -d -m bash""")
print "Started platform screen session."

os.system("""screen -t body -S body -d -m bash""")
print "Started body screen session."

os.system("""screen -t ed -S ed -d -m bash""")
print "Started ed screen session."

print "Sleeping 5s..."
time.sleep(5)

# Start the core
print "Starting roscore..."
roscore_proc    = subprocess.Popen("""screen -S roscore -p 0 -X stuff 'roscore\015'""", stdout=subprocess.PIPE, shell=True)
print roscore_proc.stdout.read()
print "Sleeping 30s..."
time.sleep(30)

print "Waiting for rosepc2 to be online..."
print 

timeout     = 120
timeout_cnt = 0
while timeout_cnt < timeout:
    if not check_ping("rosepc2"):
        print "Could not yet ping rosepc2 after {0} tries, sleeping 1s...".format(timeout_cnt)
        time.sleep(1)
        timeout_cnt += 1
        continue
    print "Successfully pinged rosepc2 after {0} tries, proceeding with boot procedure.".format(timeout_cnt)
    break

if timeout_cnt >= timeout:
    print "Could not ping rosepc2, aborting auto boot procedure."
else:
    print "Starting platform..."
    platform_proc   = subprocess.Popen("""screen -S platform -p 0 -X stuff 'roslaunch  ${LAUNCH_DIR}/platform.launch\015'""", stdout=subprocess.PIPE, shell=True)
    print platform_proc.stdout.read()
    print "Sleeping 5s..."
    time.sleep(5)
    
    print "Starting body..."
    body_proc       = subprocess.Popen("""screen -S body -p 0 -X stuff 'roslaunch ${LAUNCH_DIR}/body.launch\015'""", stdout=subprocess.PIPE, shell=True)
    print body_proc.stdout.read()

    print "Starting ed..."
    ed_proc       = subprocess.Popen("""screen -S ed -p 0 -X stuff 'roslaunch rose_ed_config ed.launch\015'""", stdout=subprocess.PIPE, shell=True)
    print ed_proc.stdout.read()

    print "All started. You can reattach to the screens with '$ screen -r roscore', '$ screen -r body', '$ screen -r platform'"
