#! /usr/bin/env python

"""Automatic access point (AP) switching
Scans for white-listed access points
Switches provided wireless interface to the best available access point if:
* There is an access point available to switch to.
* The current access point 'signal strength' falls below a certain percentage of the 'average signal strength'.
* The 'switch to' access point has a 'signal strength' which is a certain percentage better than the current AP 'signal strength'.
* A minimal 'time between switching' has passed.


Usage:
  auto_accesspoint_switching.py --interface=<interface> --impr=<improvement_percentage> [--rate=<scan_rate] [--delay=<minimal_delay>] [--whitelistfile=<white_list_file>]
  auto_accesspoint_switching.py -h | --help
  auto_accesspoint_switching.py --version

Options:
  -h --help     Show this screen.
  --version     Show version.
  --interface=<interface>  Which interface to use.
  --whitelistfile=<white_list_file>  Full path indicating the white list file. Default white listed AP ID is ROSE_WIFI.
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


def get_wpa_status():
    current_ap = {}
    try: raw = wpa_cli("status", arguments["--interface"])
    except ErrorReturnCode:
        print "Could not get wpa_cli status {0}".format(arguments["--interface"])
        return None

    properties = {}
    # Remove lines without '=' sign
    raw_properties = [line.split("=", 1) for line in raw.split("\n") if "=" in line]
    properties = {prop[0]:prop[1] for prop in raw_properties}

    return properties

def get_current_ap(aps):
    if len(aps) == 0:
        return None

    wpa_status = get_wpa_status()
    if "wpa_state" in wpa_status:
        if wpa_status["wpa_state"] == "COMPLETED":

            if not "bssid" in wpa_status:
                print "Error while getting current bssid."
                return None

            aps_with_correct_bssid = [ap for ap in aps if ap["BSSID"] ==  wpa_status["bssid"]]
            if len(aps_with_correct_bssid) > 1:
                print "More than one AP found with BSSID {0}, taking first.".format(wpa_status["bssid"])
    
            if len(aps_with_correct_bssid) == 0:
                print "Scan did not detect current AP with BSSID {0}.".format(wpa_status["bssid"])
                return None

            return aps_with_correct_bssid[0]

        elif wpa_status["wpa_state"] == "SCANNING":
            print "Not yet associated with any AP."
            return None

    print "Error while getting current AP"
    return None



def select_network(ssid):
    print "Selecting network '{0}'".format(ssid)
    try:  result = wpa_cli("select_network", ssid, " -i {0}".format(arguments["--interface"]))
    except ErrorReturnCode, ex:
        print ex
        print "Could not run wpa_cli select_network {0} -i {1}".format(ssid, arguments["--interface"])
        return False
    if result == "OK":
        return True

    return False
    
def force_scan():
    print "Scanning..."
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

def get_aps(rawscan, ssid):
    print "Extracting access points with SSID {0}.".format(ssid)
    aps_list = []
    aps = rawscan.split('\n')
    for ap in aps:
        parts = ap.split("\t")
        # bssid / frequency / signal level / flags / ssid

        if ssid in parts:
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

    switched_time = time.time()
    scanned_time = time.time()

    current_access_point = None
    switched = True     # Initialize to true in order to force scan @ start

    while 1:
        
        elapsed_time = time.time() - scanned_time
        print "Elapsed time since last scan: {0:.2f}s/{1:.2f}s".format(elapsed_time, arguments["--rate"])
        if elapsed_time >= arguments["--rate"] or switched:
            force_scan()
            scanned_time = time.time()
            time.sleep(0.1)

            aps = get_aps(get_latest_raw_scan(), "ROSE_WIFI")
            current_access_point = get_current_ap(aps)
        else:
            time.sleep(0.5)     # Print refresh rate

        os.system('cls' if os.name == 'nt' else 'clear')
        if current_access_point == None:
            wpa_status = get_wpa_status()
            if "wpa_state" in wpa_status and wpa_status["wpa_state"] == "SCANNING" and len(aps) != 0:
                print "Scanning but not yet selected an access point, selecting one now..."
            else:
                print "Could not fetch current access point, making sure correct network is selected."
                select_network("ROSE_WIFI") # @todo OH [CONF]: HardCoded ROSE_WIFI
                time.sleep(1)
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

        print "\t-------bssid--------signal-----avg.-----curr.----essid---"

        candidate_aps = []
        for ap in sorted_ap_list:
            bssid   = ap[0]
            freq    = ap[1]
            dbm     = ap[2]
            flags   = ap[3]
            essid   = ap[4]

            impr_with_avg       = 100-(dbm/average) * 100.0
            impr_with_current   = 100-(dbm/current_signal_level) * 100.0
            
            if bssid == current_bssid:
                cprint("*\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, impr_with_avg, impr_with_current, essid), 'blue')
            else:
                if  impr_with_current >= arguments["--impr"]:
                    candidate_aps += [[bssid, dbm, essid]]
                    cprint("\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, impr_with_avg, impr_with_current, essid), 'green')
                else:
                    cprint("\t{0} | {1:3.0f} dBm | {2: 3.2f}% | {3: 3.2f}% | {4}".format(bssid, dbm, impr_with_avg, impr_with_current, essid), 'red')
                
        
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



             
