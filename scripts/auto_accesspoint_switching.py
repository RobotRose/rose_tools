#! /usr/bin/env python

"""Automatic access point (AP) switching
Scans for white-listed access points
Switches provided wireless interface to the best available access point if:
* There is an access point available to switch to.
* The current access point 'signal strength' falls below a certain percentage of the 'average signal strength'.
* The 'switch to' access point has a 'signal strength' which is a certain percentage better than the current AP 'signal strength'.
* A minimal 'time between switching' has passed.


Usage:
  auto_accesspoint_switching.py --interface=<interface> --low=<low_percentage> --impr=<improvement_percentage> [--rate=<scan_rate] [--delay=<minimal_delay>] [--whitelistfile=<white_list_file>]
  auto_accesspoint_switching.py -h | --help
  auto_accesspoint_switching.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.
  --interface=<interface>  Which interface to use.
  --whitelistfile=<white_list_file>  Full path indicating the white list file. Default white listed AP ID is ROSE_WIFI.
  --low=<low_percentage>  As soon as signal strength is below this percentage [0-100%], of the average signal strength, switching will be preferred.
  --impr=<improvement_percentage>  The minimal improvement to gain from switching [0-100%].
  --delay=<minimal_delay>  Minimal switching delay in seconds [default: 10.0].
  --rate=<scan_rate>  Scan delay in seconds [default: 5.0].
"""

from docopt import docopt
from sh import iwconfig, iwlist, egrep, killall,dhclient, ErrorReturnCode, wpa_cli
from termcolor import colored, cprint
import os
import pprint
import sys
import time


def get_current_ap_bssid():
    current_ap = {}
    try: raw = wpa_cli("status", arguments["--interface"])
    except ErrorReturnCode:
        print "Could not get wpa_cli status {0}".format(arguments["--interface"])
        return None

    key = raw.split("\n")[1].split("=")[0]
    if key == "bssid":
        bssid = raw.split("\n")[1].split("=")[1]
    else:
        bssid = None
    return bssid

def get_current_ap(aps):
    if len(aps) == 0:
        return None

    current_bssid = get_current_ap_bssid()
    if get_current_ap_bssid == None:
        return None

    aps_with_correct_bssid = [ap for ap in aps if ap["BSSID"] == current_bssid]
    if len(aps_with_correct_bssid) > 1:
        print "More than one AP found with BSSID {0}, taking first.".format(current_bssid)
    
    if len(aps_with_correct_bssid) == 0:
        return None

    return aps_with_correct_bssid[0]
    
def force_scan():
    try:  wpa_cli("scan", arguments["--interface"])
    except ErrorReturnCode:
        print "Could not run wpa_cli scan {0}".format(arguments["--interface"])

def get_latest_raw_scan():
    # Limit the rate
    time.sleep(0.1)
    
    try: raw = wpa_cli("scan_results", arguments["--interface"])
    except ErrorReturnCode:
        print "Could not run wpa_cli scan_results {0}".format(arguments["--interface"])
        return ""

    return raw

def get_aps(rawscan):
    aps_list = []
    aps = rawscan.split('\n')
    for ap in aps:
        parts = ap.split("\t")
        # bssid / frequency / signal level / flags / ssid

        if "ROSE_WIFI" in parts:
            values = {}
            values["BSSID"]     = parts[0].encode("ascii", "ignore")
            values["frequency"] = float(parts[1].encode("ascii", "ignore"))
            values["dBm"]       = float(parts[2].encode("ascii", "ignore"))
            values["flags"]     = parts[3].encode("ascii", "ignore")
            values["ESSID"]     = parts[4].encode("ascii", "ignore")
            aps_list += [values]
    
    return aps_list

def switch_to_ap(access_point_bssid):
    wpa_cli("roam", access_point_bssid) 

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

    if (float(arguments["--rate"]) <= 0):
        cprint("parameter 'rate' should be a numeric value larger than zero", 'red')
        exit(1)
    else:
        arguments["--rate"] = float(arguments["--rate"])

    if (float(arguments["--delay"]) <= 0):
        cprint("parameter 'delay' should be a numeric value larger than zero", 'red')
        exit(1)
    else:
        arguments["--delay"] = float(arguments["--delay"])

    # switch_to_ap("38:2C:4A:66:E9:40")
    switched_time = time.time()
    scanned_time = time.time()

    #Startup
    force_scan()
    time.sleep(1)
    aps = get_aps(get_latest_raw_scan())
    time.sleep(1)

    current_access_point = None
    switched = False

    while 1:
        
        elapsed_time = time.time() - scanned_time
        print "Elapsed time since last scan: {0:.2f}s/{1:.2f}s".format(elapsed_time, arguments["--rate"])
        if elapsed_time >= arguments["--rate"] or switched:
            print "Scanning..."
            force_scan()
            scanned_time = time.time()
            time.sleep(0.1)

            aps = get_aps(get_latest_raw_scan())
            current_access_point = get_current_ap(aps)
        else:
            time.sleep(0.5)     # Print refresh rate

        # os.system('cls' if os.name == 'nt' else 'clear')
        if current_access_point == None:
            print "Could not fetch current access point, retrying in 3s..."
            time.sleep(3)
            continue

        # pprint.pprint("Current access point: {0} | {1} dBm".format(current_access_point["BSSID"], current_access_point["dBm"]))
        # pprint.pprint(aps)

        # # Check for len(mac_map is not null)
        average = 0
        if len(aps) != 0:
            for ap in aps:
                average += ap["dBm"]

            average /= len(aps)

        ap_list = []
        for ap in aps:
            ap_list += [[ap["BSSID"], ap["frequency"], ap["dBm"], ap["flags"], ap["ESSID"]]]

        sorted_ap_list = sorted(ap_list, key=lambda x: x[2], reverse=True)

        # print sorted_ap_list
        current_bssid = current_access_point["BSSID"]
        current_signal_level = current_access_point["dBm"]

        candidate_aps = []
        for ap in sorted_ap_list:
            bssid   = ap[0]
            freq    = ap[1]
            dbm     = ap[2]
            flags   = ap[3]
            essid   = ap[4]

            precentage_of_average = 100-(dbm/average) * 100.0
            percentage_diff_with_current = (current_signal_level/dbm) * 100.0 - 100
            
            if bssid == current_bssid:
                cprint("*\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, precentage_of_average, percentage_diff_with_current, essid), 'blue')
            else:
                if percentage_diff_with_current >= arguments["--impr"]:
                    candidate_aps += [[bssid, dbm, essid]]
                    cprint("\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, precentage_of_average, percentage_diff_with_current, essid), 'green')
                else:
                    cprint("\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, precentage_of_average, percentage_diff_with_current, essid), 'red')
                
        
        print "\t-------------------------------"
        print "\tAverage             {0:3.0f} dBm".format(average)


        elapsed_time = time.time() - switched_time
        print "Elapsed time since last switch: {0:.2f}s/{1:.2f}s".format(elapsed_time, arguments["--delay"])

        switched = False
        if len(candidate_aps) > 0 and elapsed_time >= arguments["--delay"]:
             print "Switching to access point {0}".format(candidate_aps[0][0])
             switch_to_ap(candidate_aps[0][0])
             switched_time = time.time()
             switched = True

        elif len(candidate_aps) > 0 and elapsed_time < arguments["--delay"]:
             print "Not switching to access point {0}, because of minimal delay between switching: {1:.2f}s/{2:.2f}s".format(candidate_aps[0][0], elapsed_time, arguments["--delay"])



             