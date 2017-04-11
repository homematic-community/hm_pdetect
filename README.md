## FRITZ!-based Presence Detection for HomeMatic - hm_pdetect

[![Release](https://img.shields.io/github/release/jens-maus/hm_pdetect.svg)](https://github.com/jens-maus/hm_pdetect/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/jens-maus/hm_pdetect/latest/total.svg)](https://github.com/jens-maus/hm_pdetect/releases/latest)
[![Issues](https://img.shields.io/github/issues/jens-maus/hm_pdetect.svg)](https://github.com/jens-maus/hm_pdetect/issues)
[![License](http://img.shields.io/:license-lgpl3-blue.svg?style=flat)](http://www.gnu.org/licenses/lgpl-3.0.html)
[![Donate](https://img.shields.io/badge/donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=RAQSDY9YNZVCL)

This CCU-Addon allows to implement a general home presence detection system within a [eQ3 HomeMatic](http://www.homematic.com/) homeautomation system. It regularly queries the WiFi/LAN status of user devices (e.g. Smartphones) logging in/out of [AVM FRITZ!](http://www.avm.de/) WiFi routers (e.g. FRITZ!Box, FRITZ!Repeater). Upon manually configured MAC and IP addresses of user devices this addon is able to set the general home presence status of that user in terms of setting CCU-based system variables. These variables can then be evaluated within the general HomeMatic home automation system. In addition, any device that is not recognized as a configured user devices or known device will otherwise be considered a guest device and a separate system variable set accordingly. This allows to identify any guests being present at the house so that e.g. the heating system of a guest room could be switched on/off accordingly.

## Features
* Querying of several FRITZ!-devices (FRITZ!Box/Repeater) in one run
* User-definable interval for querying FRITZ!-devices regularly
* Support for manually triggering execution via CUxD SystemExec calls.
* Support for FRITZ!Box/Repeater local network login with and without password
* Possibility to remotely query FRITZ!-devices via https
* Support for querying a dedicated guest-WiFi network
* User device definition based on MAC and/or IP address
* Possibility to define multiple devices per user
* Automatically generates all necessary CCU system variables
* Additional String and Enum system variable to easily display the general presence status at home
* Guest detection based on unknown devices being identified in a dedicated Guest-WiFi
* Guest detection can be applied to the whole WiFi/LAN environment
* Web based configuration pages accessible via CCU-WebUI

## Supported CCU models
* HomeMatic CCU1
* [HomeMatic CCU2](http://www.eq-3.de/produkt-detail-zentralen-und-gateways/items/homematic-zentrale-ccu-2.html)
* [RaspberryMatic](http://homematic-forum.de/forum/viewtopic.php?f=56&t=26917)

## Supported FRITZ! models
* All models of FRITZ!Box and FRITZ!Repeater running with FRITZ!OS 6 or newer

## Configuration FRITZ! device
1. Open the web configuration of the individual FRITZ!-device (e.g. http://fritz.box/)
2. Create a new dedicated user via *System->FRITZ!Box-User->Add User*
  * Restrict access rights of user to *FRITZ!Box Settings* only
3. Open the Homenetwork-Login configuration at *System->FRITZ!Box-User->Login to Homenetwork*
  * Modify login setting to *Login with FRITZ!Box-Username and Password*

## Installation as CCU Addon
1. Download of recent Addon-Release from [Github](https://github.com/jens-maus/hm_pdetect/releases)
2. Installation of Addon archive (```hm_pdetect-X.X.tar.gz```) via WebUI interface of CCU device
3. Configuration of FRITZ!Box/Repeater (see next section)
4. Configuration of Addon using the WebUI accessible config pages

## Manual Installation as stand-alone script (e.g. on RaspberryPi)
1. Create a new directory for hm_pdetect:

        mkdir /opt/hm_pdetect

2. Change to new directory: 

        cd /opt/hm_pdetect

3. Download latest hm_pdetect.sh:

        wget https://github.com/jens-maus/hm_pdetect/raw/master/hm_pdetect.sh

4. Download of sample config:

        wget https://github.com/jens-maus/hm_pdetect/raw/master/hm_pdetect.conf.sample

5. Rename sample config to active one:

        mv hm_pdetect.conf.sample hm_pdetect.conf

6. Modify configuration according to comments in config file:

        vim hm_pdetect.conf

7. Execute hm_pdetect manually:

        /opt/hm_pdetect/hm_pdetect.sh

8. If you want to automatically start hm_pdetect on system startup a startup script

## CUxD SystemExec use
Instead of automatically calling hm_pdetect on a predefined interval one can also trigger its execution using a CUxD (www.cuxd.de) SystemExec call within HomeMatic scripts on the CCU following the following syntax:

        dom.GetObject("CUxD.CUX2801001:1.CMD_EXEC").State("/usr/local/addons/hm_pdetect/run.sh <iterations> <waittime> &");
 
Please note the &lt;iterations&gt; and &lt;waittime&gt; which allows to additionally specify how many times hm_pdetect should be executed with a certain amount of wait time in between. One example of such an execution can be:

        dom.GetObject("CUxD.CUX2801001:1.CMD_EXEC").State("/usr/local/addons/hm_pdetect/run.sh 5 2 &");

This will execute hm_pdetect for a total amount of 5 times with a waittime of 2 seconds between each execution.

## Support
In case of problems/bugs or if you have any feature requests please feel free to open a [new ticket](https://github.com/jens-maus/hm_pdetect/issues) at the Github project pages. To seek for help for configuring/using this Addon please use the following german language based fora thread: [hm_pdetect](http://homematic-forum.de/forum/viewtopic.php?f=18&t=23907).

## License
The use and development of this addon is based on version 3 of the LGPL open source license.

## Authors
Copyright (c) 2015-2016 Jens Maus &lt;mail@jens-maus.de&gt;

## Notice
This Addon uses KnowHow that was developed throughout the following projects:
* https://github.com/jollyjinx/homematic
* https://github.com/max2play/webinterface
