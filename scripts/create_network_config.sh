#!/bin/bash


read -p "Please enter WPA2 SSID: " SSID
read -s -p "Please enter WPA2 pass phrase: " PASS

wpa_supplicant $SSID $PASS
