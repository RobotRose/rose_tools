#! /usr/bin/env python
import os
import os.path
import subprocess
import time
import sys
import socket

# Rose B.V.
# Author: Okke Hendriks
# Date: 05-09-2014
# Script to configure the serial ports



#Global vars 
configFilename = os.path.expanduser("~/.udev_rules_config")
rosepc1_controllerNames = [ "power_controller", "bihand" ]
rosepc2_controllerNames = [ "platform_controller", "lift_controller", "neck_controller" ]

configurationSuccessKey = "configurationSuccess"

hostname = ""

# Functions
def getConnectedSerial(tty_id): 
    proc = subprocess.Popen("""udevadm info --attribute-walk --path=/sys/bus/usb-serial/devices/ttyUSB{0} | grep serial -n | grep 51 | grep -Po '\"(.*?)\"' | grep -Po '(\d|\w)*'""".format(tty_id), stdout=subprocess.PIPE, shell=True)
    serial_id = proc.stdout.read()

    return serial_id.strip()

def getNrOfttyUSB():
    proc = subprocess.Popen("""ls /dev | grep -o 'ttyUSB' | wc -l""", stdout=subprocess.PIPE, shell=True)
    nr_of_ttyUSB = proc.stdout.read()

    return int(nr_of_ttyUSB.strip())
    
def getConnectedttyUSBid():    
    proc = subprocess.Popen("""ls /dev | grep ttyUSB | grep -Po '[0-7]'""", stdout=subprocess.PIPE, shell=True)
    ttyUSBID = proc.stdout.read()

    return int(ttyUSBID.strip())
    
def saveIDtoFile(name, serialID, silent=False):
    if not silent:
        print "Saving {0} with serial id {1}".format(name, serialID)
    f = open(configFilename,'a+')
    f.write('{0} {1}\n'.format(name, serialID))
    f.close()
    return True
    
def readFile():
    d = {}
    with open(configFilename, 'r') as f:
        for line in f:
            (key, val) = line.split()
            d[key] = val
    return d    
    
def isConfigOK(controllerNames):
    if not os.path.isfile(configFilename):
        return False
    
    configuration = readFile()
    if "configurationSuccess" in configuration:
        if bool(configuration["configurationSuccess"]):
            return True

    return False
    
def connectGetSave(name):
    try:
        while not getNrOfttyUSB() == 1:
            print "Connect the {0} ttyUSB device, {1} ttyUSB's connected. Press CRTL+C to skip.".format(name, getNrOfttyUSB())
            time.sleep(1)
    except KeyboardInterrupt:
        return
    print "ttyUSB{0} detected, {1} has serial number: {2}.".format(getConnectedttyUSBid(), name, getConnectedSerial(getConnectedttyUSBid()))
    saveIDtoFile(name, getConnectedSerial(getConnectedttyUSBid()))     

def waitForDisconnect(sleep):
    while getNrOfttyUSB() > 0:
        print "Disconnect all ttyUSB devices, {0} ttyUSB's connected".format(getNrOfttyUSB())
        time.sleep(sleep)
    
def getControllerNames(hn):    
    if hn == "rosepc1":
        return rosepc1_controllerNames  
    elif hn == "rosepc2":
        return rosepc2_controllerNames

    print "You have to specify the hostname 'rosepc1' or 'rosepc2' as the second argument, you specified {0}.".format(hn)
    quit(1)
       
    
# Start of program ===============================================
if __name__ == "__main__":
    
         
    if len(sys.argv) == 2:
        hostname = sys.argv[1]
    elif len(sys.argv) == 3:
        hostname = sys.argv[1]
        if sys.argv[2] == "reconfigure":
            print "UDEV rules configuration file exists, but going to reconfigure." 
        else:
            print "Unkown argument, try 'reconfigure'."
            exit(1)  

    # Checking PC name
    controllerNames = getControllerNames(hostname)
    print "Configuring UDEV rules for {0}".format(hostname)

    # Check if config file exists
    if len(sys.argv) == 2 and isConfigOK(controllerNames):
        print "UDEV rules configuration file exists, and is ok. Use 'reconfigure' as the second parameter in order to force reconfigure."    
        exit(0)

    if os.path.isfile(configFilename):
        os.remove(configFilename)
                     
    print "Starting UDEV rules configuration."

    for name in controllerNames:
        waitForDisconnect(1)
        print "---"
        connectGetSave(name)
        print "---"
        
    print "All devices succesfully configured for {0}! Do not forget to run setup_udev_rules.py.".format(hostname)
    saveIDtoFile(configurationSuccessKey, "True", True) 
    exit(0)    
    
