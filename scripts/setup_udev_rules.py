#! /usr/bin/env python
import os
import getpass
from config_serial_udev_rules import *
 
# Rose B.V.
# Author: Okke Hendriks
# Date: 05-09-2014
# Script to setup the UDEV rules

# udevadm info -a -p $(udevadm info -q path -n /dev/ttyUSB0) | grep "serial"

RULES_FILE = "/etc/udev/rules.d/10-local.rules"

# Check if sudo
if not os.getenv("USER") == "root":
    print "{0}, run this script as root!".format(os.getenv("USER"))
    exit(1)
    

print "Creating UDEV rules for usb2ser devices:" 


hostname = socket.gethostname()
if len(sys.argv) == 2:
    hostname = sys.argv[1]

if not isConfigOK(getControllerNames(hostname)):
    print "UDEV configuration file is not present or not valid, try running config_serial_udev_rules.py."
else:
    # Add user to dailout group
    user = os.getenv("SUDO_USER")
    print "Adding user '{0}' to dailout group.".format(user)
    os.system("adduser {0} dialout".format(user))
    
    os.system("""cp {0} {0}.backup.$(date +"%H_%M_%S")""".format(RULES_FILE))
    
    # Read the configuration
    config = readFile()
    

    f = open(RULES_FILE,'w+')
    for name in config:
        if not name == configurationSuccessKey:
            rule = """SUBSYSTEM=="tty", KERNEL=="ttyUSB[0-9]*", ATTRS{{idVendor}}=="0403", ATTRS{{idProduct}}=="6001", ATTRS{{serial}}=="{0}", MODE="0666", NAME="usb2serial/{1}", GROUP="dialout\"""".format(config[name], name)
            print " Adding: {0} with serial id {1}".format(name, config[name])
            f.write('{0}\n'.format(rule))        
    f.close()
        
    print " Reloading udev-rules"
    os.system("""udevadm control --reload-rules""")
    print "Done."
    exit(0)
   
