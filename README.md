# hm_pdetect
A FRITZ!-based Homematic presence detection script which can be regularly executed (e.g. via cron on a separate Linux system) and remotely queries a FRITZ! device about the registered LAN/WLAN devices.

## Introduction
Based on a device list specified in the config file (HM_USER_LIST) certain system variables are then set in the corresponding CCU so that users are being recognized as being present or away. In addition guests are being identified by also specifying other known devices in a separate list (HM_KNOWN_LIST) and if a device is found that is not either in the user list or known list it will be recognized as a guest device and the script will set a presence system variable for guests in the CCU as well.

## Features
* Identifies presence of persons (HM_USER_LIST) based on MAC or IP-addresses registered to FRITZ! devices
* Identifies presence of guests by identifying unknown devices being active in the LAN/WLAN by specifying all known MAC or IP-addresses (HM_KNOWN_LIST) 
* Can query any number of FRITZ! devices (e.g. FRITZ!Box or FRITZ!repeater for LAN/WLAN devices)
* Automatically creates all requires CCU system variables - no need to create them in advance.
* No installation on FRITZ! device required (simply cronjob on Linux/RaspberryPi is enough)

## Installation
1. Checkout this repository via

   ```
   git checkout https://github.com/jens-maus/hm_pdetect.git
   ```

2. Copy sample config file to actual config file:

   ```
   cd hm_pdetect
   cp hm_pdetect.conf.sample hm_pdetect.conf
   ```

3. Edit config file and add all necessary information (HM_* variables):

   ```
   vi hm_pdetect.conf
   ```

4. run hm_pdetect script and check your CCU for the system variables being properly added/modified.

5. create cronjob on your Linux/Unix system to reguarly call the script (e.g. every minute):

   ```
   crontab -e
   ```

  add/adapt this:
   ```
   # run hm_pdetect.sh every minute and stuff all output to /dev/null
   */1 * * * * /<directory>/hm_pdetect.sh 2>&1 >/dev/null
   ```

6. Enjoy and adapt your CCU scripts to recognize the presense.XXXX system variables changes for your various home automatisation purposes.

## Note
This script is based on similar functionality and combines the functionality of these projects into a single script:
* https://github.com/jollyjinx/homematic
* https://github.com/max2play/webinterface

## Author
Copyright (C) 2015 Jens Maus <mail@jens-maus.de>
