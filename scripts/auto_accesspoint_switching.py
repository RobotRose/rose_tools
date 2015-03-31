#! /usr/bin/env python

"""Automatic access point (AP) switching
Scans for white-listed access points
Switches provided wireless interface to the best available access point if:
* There is an access point available to switch to.
* The current access point 'signal strength' falls below a certain percentage of the 'average signal strength'.
* The 'switch to' access point has a 'signal strength' which is a certain percentage better than the current AP 'signal strength'.
* A minimal 'time between switching' has passed.


Usage:
  auto_accesspoint_switching.py --interface=<interface> --low=<low_percentage> --impr=<improvement_percentage> [--delay=<minimal_delay>] [--whitelistfile=<white_list_file>]
  auto_accesspoint_switching.py -h | --help
  auto_accesspoint_switching.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.
  --interface=<interface>  Which interface to use.
  --whitelistfile=<white_list_file>  Full path indicating the white list file. Default white listed AP ID is ROSE_WIFI.
  --low=<low_percentage>  As soon as signal strength is below this percentage [0-100%], of the average signal strength, switching will be preferred.
  --impr=<improvement_percentage>  The minimal improvement to gain from switching [0-100%].
  --delay=<minimal_delay>  Minimal switching delay in seconds [default: 10].
"""

from docopt import docopt
from sh import iwconfig, iwlist, egrep, killall,dhclient, ErrorReturnCode
from termcolor import colored, cprint
import os
import pprint
import sys
import time


def get_raw_current_ap():
    current_ap = {}
    raw = iwconfig(arguments["--interface"])
    current_ap["BSSID"] = [line.split("Access Point: ", 1)[1].strip().encode("ascii", "ignore") for line in raw.split("\n") if "Access Point: " in line][0]
    current_ap["dBm"]   = [float(line.split("Signal level=", 1)[1].strip().split(" ", 1)[0].encode("ascii", "ignore")) for line in raw.split("\n") if "Signal level=" in line][0]
    return current_ap

def get_raw_scan():
    return egrep(iwlist(arguments["--interface"], "scan"), "-A 5", "-B 5", "ROSE_WIFI")

def get_raw_aps(rawscan):

    aps = rawscan.split('--')
    for ap in aps:
        parts = ap.split("  ")

        def parse_raw(parts):
            for part in parts:
                part = part.replace("=", ":").strip()
                split = part.split(':', 1)
                if len(split) >= 2:
                    yield split[0], split[1].replace('"', '').strip()

        values = dict(parse_raw(parts))
        yield values

def switch_to_ap(access_point_bssid):
    try: killall("dhclient")
    except ErrorReturnCode:
        print "No dhclient to kill!"

    iwconfig(arguments["--interface"], "ap", access_point_bssid) 
    dhclient(arguments["--interface"])

def process_raw_scan(rawscan):
    mac_map = {}
    raw_aps = list(get_raw_aps(rawscan))
    for ap in raw_aps:
        mac = [value.encode("ascii", "ignore") for key,value in ap.iteritems() if "Address" in key][0]
        mac_map[mac] = ap

    # pprint.pprint(mac_map)

    # Pre-Process data items
    for mac, data in mac_map.iteritems():
        for k,v in data.iteritems():
            if k == "Signal level":
                parts = v.split(" ")
                data[k] = float(parts[0])

    return mac_map

if __name__ == '__main__':
    arguments = docopt(__doc__, version='WiFi switching')
    print arguments

    if not (0 <= float(arguments["--low"]) <= 100):
        cprint("parameter 'low' should be a numeric value in the range [0-100]", 'red')
        exit(1)
    else:
        arguments["--low"] = float(arguments["--low"])

    if not (0 <= float(arguments["--impr"]) <= 100):
        cprint("parameter 'impr' should be a numeric value in the range [0-100]", 'red')
        exit(1)
    else:
        arguments["--impr"] = float(arguments["--impr"])

    switch_to_ap("38:2C:4A:66:E9:40")

    while 1:
        current_access_point = get_raw_current_ap()
        # pprint.pprint("Current access point: {0} | {1}".format(current_access_point["BSSID"], current_access_point["dBm"]))

        mac_map = process_raw_scan(get_raw_scan())

        pprint.pprint(mac_map)

        # Check for len(mac_map is not null)
        average = sum([data["Signal level"] for mac, data in mac_map.iteritems()])/len(mac_map)

        precentage_of_average = 100-(current_access_point["dBm"]/average) * 100.0

        macs = []
        candidate_macs = []

        os.system('cls' if os.name == 'nt' else 'clear')

        for mac, data in mac_map.iteritems():
            macs += [[mac, mac_map[mac]["Signal level"], mac_map[mac]["ESSID"]]]

        sorted_macs = sorted(macs, key=lambda x: x[1], reverse=True)

        current_bssid = current_access_point["BSSID"]
        current_signal_level = current_access_point["dBm"]
        for mac, signal_level, essid in sorted_macs:

            percentage_diff_with_current = (current_signal_level/signal_level) * 100.0 - 100
            

            if mac == current_bssid:
                cprint("* {0} | {1:3.0f} dBm | {2: 3.2f}% | {3}".format(mac, signal_level, precentage_of_average, essid), 'blue')
            else:
                if percentage_diff_with_current >= arguments["--impr"]:
                    candidate_macs += [[mac, signal_level, essid]]
                    cprint("  {0} | {1:3.0f} dBm | {2: 3.2f}% | {3}".format(mac, signal_level, percentage_diff_with_current, essid), 'green')
                else:
                    cprint("  {0} | {1:3.0f} dBm | {2: 3.2f}% | {3}".format(mac, signal_level, percentage_diff_with_current, essid), 'red')
                
        
        print "  -------------------------------"
        print "  Average             {0:3.0f} dBm".format(average)


        
        print "Sorted candidates:"
        pprint.pprint(candidate_macs)

        if len(candidate_macs) > 0:
            print "Switching to access point {0}".format(candidate_macs[0])
            switch_to_ap(candidate_macs[0][0])
            