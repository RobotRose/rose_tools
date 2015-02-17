#! /usr/bin/env python

import numpy as np
import os, sys
from math import *
import datetime
import csv
import matplotlib.pyplot as plt
import pylab

logging_dir = "~/git/rose2_0/logging"
logging_dir = os.path.expanduser(logging_dir)

#Fieldnames according to timing-functions:
#date YY-MM_DD, TIME HH:MM:SS, nanoseconds, username, hostname, dir, command, exit state, user time, system time, real time, filesys inputs, filesys outputs
fieldnames = [  "day", "time", "nano", 
                "username", "hostname", "dir", 
                "command", "exit state", 
                "user time", "system time", "real time", 
                "filesys inputs", "filesys outputs"]

logging_files = []
# import ipdb; ipdb.set_trace()
for root, dirs, files in os.walk(logging_dir):
    for f in files:
        logging_files += [os.path.join(logging_dir, f)]

logging_entries = []
for log in logging_files:
    csv_log = csv.DictReader(open(log), fieldnames=fieldnames)

    logging_entries.extend(csv_log)

real_times = [float(entry["real time"]) for entry in logging_entries]
print "Average real time: {0}s".format(sum(real_times)/len(real_times))