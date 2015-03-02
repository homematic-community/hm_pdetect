#!/bin/bash
#
# A FRITZ!-based Homematic presence detection script which can be regularly
# executed (e.g. via cron on a separate Linux system) and remotely queries a FRITZ!
# device about the registered LAN/WLAN devices.
#
# This script can be found at https://github.com/jens-maus/hm_pdetect
#
# Based on a device list specified in the config file (HM_USER_LIST) certain system
# variables are then set in the corresponding CCU so that users are being recognized
# as being present or away. In addition guests are being identified by also specifying
# other known devices in a separate list (HM_KNOWN_LIST) and if a device is found
# that is not either in the user list or known list it will be recognized as a
# guest device and the script will set a presence system variable for guests in the
# CCU as well.
#
# Copyright (C) 2015 Jens Maus <mail@jens-maus.de>
#
# This script is based on similar functionality and combines the functionality of
# these projects into a single script:
#
# https://github.com/jollyjinx/homematic
# https://github.com/max2play/webinterface
#
# Version history:
# 0.1 (2015-03-02): initial release
# 

CONFIG_FILE="hm_pdetect.conf"
NC="/bin/nc"

#####################################################
# Main script starts here, don't modify

# declare all associative arrays first
declare -A HM_USER_LIST   # username<>MAC/IP tuple
declare -A deviceList     # MAC<>IP tuple

if [ -e "$(dirname $0)/${CONFIG_FILE}" ]; then
  source "$(dirname $0)/${CONFIG_FILE}"
else
  echo "ERROR: config file ${CONFIG_FILE} doesn't exist"
fi

RETURN_FAILURE=1
RETURN_SUCCESS=0

# function querying and setting system variables
# on a CCU
getorsetpresenceVariableState()
{
  local name=$1
  local setstate=$2
 
  if [ "${setstate}" != "" ]; then

    local currentstate=$(getorsetpresenceVariableState ${name})

    if [ "${currentstate}" == "${setstate}" ]; then
      echo -n "${currentstate}"
      return $RETURN_SUCCESS
    fi
  fi

  local wgetreturn=$(wget -q -O - "http://${HM_CCU_IP}:8181/rega.exe?state=dom.GetObject('presence.${name}').State(${setstate})" | egrep -o '<state>(false|true)</state></xml>$')

  if [ "<state>true</state></xml>" == "$wgetreturn" ]; then
    return $RETURN_SUCCESS
  fi
    
  if [ "<state>false</state></xml>" == "$wgetreturn" ]; then
    return $RETURN_SUCCESS
  fi

  return $RETURN_FAILURE
}

# function to check if a certain boolean system variable exists
# at a CCU and if not creates it accordingly
createPresenceVariableOnCCUIfNeeded()
{
  local name=$1

  getorsetpresenceVariableState ${name} >/dev/null && return $RETURN_SUCCESS
    
  if [ ! -f ${NC} ]
  then
    echo "WARNING: ${NC} does not exist you need to create variable 'preseṅce.${name}' on CCU2 manually"
    return $RETURN_FAILURE
  fi
    
  local postbody="string name='${name}';string v='presence.${name}';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(2);n.DPInfo(name#' is at home');n.ValueName1('anwesend');n.ValueName0('abwesend');n.State(false);dom.RTUpdate(0);}"
  local postlength=$(echo "$postbody" | wc -c)
  echo -e "POST /tclrega.exe HTTP/1.0\r\nContent-Length: $postlength\r\n\r\n$postbody" | ${NC} "${HM_CCU_IP}" 80 >/dev/null 2>&1

  getorsetpresenceVariableState ${name} >/dev/null
}

# function that logs into a FRITZ! device and stores the MAC and IP address of all devices
# in an associative array which have to bre created before calling this function
retrieveFritzBoxDeviceList()
{
  local ip=$1
  local user=$2
  local secret=$3

  # retrieve login challenge
  local challenge=$(wget -O - "http://${ip}/login_sid.lua" 2>/dev/null | sed 's/.*<Challenge>\(.*\)<\/Challenge>.*/\1/')

  # process login and hash it with our password
  local cpstr="${challenge}-${secret}"
  local md5=$(echo -n ${cpstr} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | awk '{print substr($0,1,32)}')
  local response="${challenge}-${md5}"
  local url_params="username=${user}&response=${response}"
  
  # send login request and retrieve SID return
  local sid=$(wget -O - "http://${ip}/login_sid.lua?${url_params}" 2>/dev/null | sed 's/.*<SID>\(.*\)<\/SID>.*/\1/')
 
  # retrieve the network device list from the fritzbox and filter it
  # to show only the part between "uiLanActive" and "uiLanPassive" which should include all
  # currently connected devices.
  local devices=$(wget -O - "http://${ip}/net/network_user_devices.lua?sid=${sid}" 2>/dev/null | grep uiLanActive | sed 's/.*uiLanActive\(.*\)uiLanPassive.*/\1/')

  # extract the mac addresses of devices being active
  local maclist=($(echo ${devices} | egrep -o '>[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}<' | tr -d '><'))
  local iplist=($(echo ${devices} | egrep -o '>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}<' | tr -d '><'))

  # modify the global associative array
  for (( i = 0; i < ${#maclist[@]} ; i++ )); do
    deviceList[${maclist[$i]}]=${iplist[$i]}
  done
}

################################################
# main processing starts here
#

echo "hm_pdetect 0.1 - a FRITZ!-based homematic presence detection script"
echo "(Mar 02 2015) Copyright (C) 2015 Jens Maus <mail@jens-maus.de>"
echo


# lets retrieve all mac<>ip addresses of currently
# active devices in our network
echo -n "querying fritz devices:"
for ip in ${HM_FRITZ_IP[@]}; do
  echo -n " ${ip}"
  retrieveFritzBoxDeviceList ${ip} ${HM_FRITZ_USER} ${HM_FRITZ_SECRET}
done
echo ", devices online: ${#deviceList[@]}."

# lets identify user presence
echo "setting user presence: "
for user in "${!HM_USER_LIST[@]}"; do
  echo -n "${user}: "
  stat="false"

  # try to match MAC address first
  if [[ ${deviceList[@]} =~ ${HM_USER_LIST[${user}]} ]]; then
    stat="true"
  else
    # now match the IP address list instead
    if [[ ${!deviceList[@]} =~ ${HM_USER_LIST[${user}]} ]]; then
      stat="true"
    fi
  fi

  if [ "${stat}" == "true" ]; then
    echo present
  else
    echo away
  fi

  # set status in homematic CCU
  createPresenceVariableOnCCUIfNeeded ${user}
  getorsetpresenceVariableState ${user} ${stat}

done

# lets identify guest presence by ruling out
# devices in our list that are not listed in our HM_KNOWN_LIST
# array
for device in ${HM_KNOWN_LIST[@]}; do

  # try to match MAC address first
  if [[ ${!deviceList[@]} =~ ${device} ]]; then
    unset deviceList[${device}]
  else
    # now match the IP address list instead
    if [[ ${deviceList[@]} =~ ${device} ]]; then
      for dev in ${!deviceList[@]}; do
        if [ ${deviceList[${dev}]} == ${device} ]; then
          unset deviceList[${dev}]
          break
        fi
      done
    fi
  fi

done

echo "${#deviceList[@]} guest devices found: ${!deviceList[@]}"

# create/set presence system variable in CCU if guest devices
# were found
echo -n "guest: "
createPresenceVariableOnCCUIfNeeded guest
if [ ${#deviceList[@]} -gt 0 ]; then
  # set status in homematic CCU
  getorsetpresenceVariableState guest true
  echo present
else
  getorsetpresenceVariableState guest false
  echo away
fi
