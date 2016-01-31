#!/usr/bin/env bash
#
# A FRITZ!-based HomeMatic presence detection script which can be regularly
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
# Copyright (C) 2015-2016 Jens Maus <mail@jens-maus.de>
#
# This script is based on similar functionality and combines the functionality of
# these projects into a single script:
#
# https://github.com/jollyjinx/homematic
# https://github.com/max2play/webinterface
#
# Version history:
# 0.1 (2015-03-02): - initial release
# 0.2 (2015-03-06): - fixed bug in match for multiple user devices.
# 0.3 (2015-03-06): - fixed bug where user devices were identified as guest devices
# 0.4 (2015-06-15): - added functionality to generate an additional enum list and
#                     large general rework to have more stability fo querying and
#                     setting CCU variables
# 0.5 (2015-09-13): - added dependency checks to make sure all required third-party
#                     tools are installed and have proper versions.
# 0.6 (2015-12-03): - removed awk dependency and improved BASH version check
#                   - changed the device query to use query.lua instead
# 0.7 (2016-01-27): - device comparisons changed to be case insensitive.
#                   - an alternative config file can now be specified as a
#                     commandline option.
#                   - changed list variable to be of type 'string' to be more
#                     flexible.
#                   - the enum variable is now called "Anwesenheit.enum" per
#                     default and should be fixed compared to version 0.6.
#                   - added login/password check for fritzbox login procedure.
#                   - introduced HM_KNOWN_LIST_MODE functionality to query guest
#                     WiFi status of devices.
#                   - connection to FRITZ! devices can now be performed with https://
#                     protocol as well (have to be specified in HM_FRITZ_IP)
#                   - replaced 'sed' tool dependency by replacing all uses with
#                     equivalent bash regexp statements.
#                   - removed 'nc' tool dependency by using wget instead.
#

CONFIG_FILE="hm_pdetect.conf"

#####################################################
# Main script starts here, don't modify

# default settings (overwritten by config file)
HM_FRITZ_IP="fritz.box fritz.repeater"

# IP address/hostname of CCU2
HM_CCU_IP="homematic-ccu2.fritz.box"

# Name of a CCU variable we set for signaling general presence
HM_CCU_PRESENCE_VAR="Anwesenheit"
HM_CCU_PRESENCE_VAR_LIST="${HM_CCU_PRESENCE_VAR}.list"
HM_CCU_PRESENCE_VAR_STR="${HM_CCU_PRESENCE_VAR}.string"

# used names within variables
HM_CCU_PRESENCE_GUEST="Gast"
HM_CCU_PRESENCE_NOBODY="Niemand"
HM_CCU_PRESENCE_PRESENT="anwesend"
HM_CCU_PRESENCE_AWAY="abwesend"

# Specify mode of HM_KNOWN_LIST variable setting
#
# guest - apply known ignore list to devices in a dedicated
#         guest WiFi only (requireѕ enabled guest WiFi in 
#         FRITZ! device)
# all   - apply known ignore list to all devices
HM_KNOWN_LIST_MODE=guest

# MAC/IP addresses of other known devices (all others will be
# recognized as guest devices
HM_KNOWN_LIST=""

# global return status variables
RETURN_FAILURE=1
RETURN_SUCCESS=0

###############################
# now we check all dependencies first. That means we
# check that we have the right bash version and third-party tools
# installed
#

# bash check
if [[ $(echo ${BASH_VERSION} | cut -d. -f1) -lt 4 ]]; then
  echo "ERROR: this script requires a bash shell of version 4 or higher. Please install."
  exit ${RETURN_FAILURE}
fi

# wget check
if [[ ! -x $(which wget) ]]; then
  echo "ERROR: 'wget' tool missing. Please install."
  exit ${RETURN_FAILURE}
fi

# iconv check
if [[ ! -x $(which iconv) ]]; then
  echo "ERROR: 'iconv' tool missing. Please install."
  exit ${RETURN_FAILURE}
fi

# md5sum check
if [[ ! -x $(which md5sum) ]]; then
  echo "ERROR: 'md5sum' tool missing. Please install."
  exit ${RETURN_FAILURE}
fi

# declare all associative arrays first (bash v4+ required)
declare -A HM_USER_LIST     # username<>MAC/IP tuple
declare -A normalDeviceList # MAC<>IP tuple (normal-WiFi)
declare -A guestDeviceList  # MAC<>IP tuple (guest-WiFi)

# lets source in the user defined config file
if [ $# -gt 0 ]; then
  source "$1"
elif [ -e "${0%/*}/${CONFIG_FILE}" ]; then
  source "${0%/*}/${CONFIG_FILE}"
else
  echo "WARNING: config file ${CONFIG_FILE} doesn't exist. Using default values."
fi

# function returning the current state of a homematic variable
# and returning success/failure if the variable was found/not
function getVariableState()
{
  local name="$1"

  local result=$(wget -q -O - "http://${HM_CCU_IP}:8181/rega.exe?state=dom.GetObject('${name}').State()")
  if [[ ${result} =~ \<state\>(.*)\</state\> ]]; then
    result="${BASH_REMATCH[1]}"
    if [ "${result}" != "null" ]; then
      echo ${result}
      return ${RETURN_SUCCESS}
    fi
  fi

  echo ${result}
  return ${RETURN_FAILURE}
}

# function setting the state of a homematic variable in case it
# it different to the current state and the variable exists
function setVariableState()
{
  local name="$1"
  local newstate="$2"

  # before we going to set the variable state we
  # query the current state and if the variable exists or not
  curstate=$(getVariableState "${name}")
  if [ "${curstate}" == "null" ]; then
    return ${RETURN_FAILURE}
  fi

  # only continue if the current state is different to the new state
  if [ "${curstate}" == ${newstate//\'} ]; then
    return ${RETURN_SUCCESS}
  fi

  # the variable should be set to a new state, so lets do it
  echo -n "  Setting CCU variable '${name}': '${newstate//\'}'... "
  local result=$(wget -q -O - "http://${HM_CCU_IP}:8181/rega.exe?state=dom.GetObject('${name}').State(${newstate})")
  if [[ ${result} =~ \<state\>(.*)\</state\> ]]; then
    result="${BASH_REMATCH[1]}"
  else
    result=""
  fi

  # if setting the variable succeeded the result will be always
  # 'true'
  if [ "${result}" == "true" ]; then
    echo "ok."
    return ${RETURN_SUCCESS}
  fi

  echo "ERROR."
  return ${RETURN_FAILURE}
}

# function to check if a certain boolean system variable exists
# at a CCU and if not creates it accordingly
function createVariable()
{
  local vaname=$1
  local vatype=$2
  local comment=$3
  local valist=$4

  # first we find out if the variable already exists and if
  # the value name/list it contains matches the value name/list
  # we are expecting
  local postbody=""
  if [ "${vatype}" == "enum" ]; then
    local result=$(wget -q -O - "http://${HM_CCU_IP}:8181/rega.exe?valueList=dom.GetObject('${vaname}').ValueList()")
    if [[ ${result} =~ \<valueList\>(.*)\</valueList\> ]]; then
      result="${BASH_REMATCH[1]}"
    fi

    # make sure result is not empty and not null
    if [[ -n "${result}" ]] && \
       [[ "${result}" != "null" ]]; then

      if [[ ${result} != ${valist} ]]; then
        echo -n "  Modifying CCU variable '${vaname}' (${vatype})... "
        postbody="string v='${vaname}';dom.GetObject(v).ValueList('${valist}')"
      fi
    else
      echo -n "  Creating CCU variable '${vaname}' (${vatype})... "
      postbody="string v='${vaname}';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtInteger);n.ValueSubType(istEnum);n.DPInfo('${comment}');n.ValueList('${valist}');n.State(0);dom.RTUpdate(false);}"
    fi
  elif [ "${vatype}" == "string" ]; then
    getVariableState "${vaname}" >/dev/null
    if [ $? -eq 1 ]; then
      echo -n "  Creating CCU variable '${vaname}' (${vatype})... "
      postbody="string v='${vaname}';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtString);n.ValueSubType(istChar8859);n.DPInfo('${comment}');n.State('');dom.RTUpdate(false);}"
    fi
  else
    local result=$(wget -q -O - "http://${HM_CCU_IP}:8181/rega.exe?valueName0=dom.GetObject('${vaname}').ValueName0()&valueName1=dom.GetObject('${vaname}').ValueName1()")
    local valueName0="null"
    local valueName1="null"
    if [[ ${result} =~ \<valueName0\>(.*)\</valueName0\>\<valueName1\>(.*)\</valueName1\> ]]; then
      valueName0="${BASH_REMATCH[1]}"
      valueName1="${BASH_REMATCH[2]}"
    fi

    # make sure result is not empty and not null
    if [[ -n "${result}" ]] && \
       [[ ${valueName0} != "null" ]] && [[ ${valueName1} != "null" ]]; then

       if [[ ${valueName0} != ${HM_CCU_PRESENCE_AWAY} ]] || \
          [[ ${valueName1} != ${HM_CCU_PRESENCE_PRESENT} ]]; then
         echo -n "  Modifying CCU variable '${vaname}' (${vatype})... "
         postbody="string v='${vaname}';dom.GetObject(v).ValueName0('${HM_CCU_PRESENCE_AWAY}');dom.GetObject(v).ValueName1('${HM_CCU_PRESENCE_PRESENT}')"
       fi
    else
      echo -n "  Creating CCU variable '${vaname}' (${vatype})... "
      postbody="string v='${vaname}';boolean f=true;string i;foreach(i,dom.GetObject(ID_SYSTEM_VARIABLES).EnumUsedIDs()){if(v==dom.GetObject(i).Name()){f=false;}};if(f){object s=dom.GetObject(ID_SYSTEM_VARIABLES);object n=dom.CreateObject(OT_VARDP);n.Name(v);s.Add(n.ID());n.ValueType(ivtBinary);n.ValueSubType(istBool);n.DPInfo('${comment}');n.ValueName1('${HM_CCU_PRESENCE_PRESENT}');n.ValueName0('${HM_CCU_PRESENCE_AWAY}');n.State(false);dom.RTUpdate(false);}"
    fi
  fi

  # if postbody is empty there is nothing to do
  # and the variable exists with correct value name/list
  if [[ -z "${postbody}" ]]; then
    return ${RETURN_SUCCESS}
  fi

  # use wget to post the tcl script to tclrega.exe
  local result=$(wget -q -O - --post-data "${postbody}" "http://${HM_CCU_IP}:8181/tclrega.exe")
  if [[ ${result} =~ \<v\>${vaname}\</v\> ]]; then
    echo "ok."
    return ${RETURN_SUCCESS}
  else
    echo "ERROR: could not create system variable '${vaname}'."
    return ${RETURN_FAILURE}
  fi
}

# function that logs into a FRITZ! device and stores the MAC and IP address of all devices
# in an associative array which have to bre created before calling this function
function retrieveFritzBoxDeviceList()
{
  local ip=$1
  local user=$2
  local secret=$3

  # check if "ip" starts with a "http(s)://" URL scheme
  # identifier or if we have to add it ourself
  if [[ ! ${ip} =~ ^http(s)?:\/\/ ]]; then
    uri="http://${ip}"
  else
    uri=${ip}
  fi

  # retrieve login challenge
  local challenge=$(wget -q -O - --no-check-certificate "${uri}/login_sid.lua")
  if [[ ${challenge} =~ \<Challenge\>(.*)\</Challenge\> ]]; then
    challenge="${BASH_REMATCH[1]}"
  else
    challenge=""
  fi

  # check if we retrieved a valid challenge
  if [[ -z "${challenge}" ]]; then
    echo
    echo "WARNING: could not connect to ${uri}. Please check hostname/ip or URI."
    return ${RETURN_FAILURE}
  fi

  # process login and hash it with our password
  local cpstr="${challenge}-${secret}"
  local md5=$(echo -n ${cpstr} | iconv -f ISO8859-1 -t UTF-16LE | md5sum -b | cut -d' ' -f1)
  local response="${challenge}-${md5}"
  local url_params="username=${user}&response=${response}"
  
  # send login request and retrieve SID
  local sid=$(wget -q -O - --no-check-certificate "${uri}/login_sid.lua?${url_params}")
  if [[ ${sid} =~ \<SID\>(.*)\</SID\> ]]; then
    sid="${BASH_REMATCH[1]}"
  else
    sid=""
  fi
 
  # check if we got a valid SID
  if [ -z "${sid}" ] || [ "${sid}" == "0000000000000000" ]; then
    echo
    echo "ERROR: username or password incorrect."
    exit ${RETURN_FAILURE}
  fi

  # retrieve the network device list from the fritzbox using a
  # specific call to query.lua so that we get our information without
  # having to parse HTML portions.
  local devices=$(wget -q -O - --no-check-certificate "${uri}/query.lua?sid=${sid}&network=landevice:settings/landevice/list(name,ip,mac,guest,active)")

  #echo "devices: '${devices}'"

  # prepare the regular expressions
  local re_name="\"name\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  local re_ip="\"ip\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  local re_mac="\"mac\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  local re_guest="\"guest\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  local re_active="\"active\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""

  local maclist_normal=()
  local iplist_normal=()
  local maclist_guest=()
  local iplist_guest=()
  local name=""
  local ipaddr=""
  local mac=""
  local guest=0
  local active=0

  # parse the query.lua output
  while read -r line; do
    # extract name
    if [[ $line =~ $re_name ]]; then
      name="${BASH_REMATCH[1]}"
    elif [[ $line =~ $re_ip ]]; then
      ipaddr="${BASH_REMATCH[1]}"
    elif [[ $line =~ $re_mac ]]; then
      mac="${BASH_REMATCH[1]}"
    elif [[ $line =~ $re_guest ]]; then
      guest="${BASH_REMATCH[1]}"
    elif [[ $line =~ $re_active ]]; then
      active="${BASH_REMATCH[1]}"

      # only add 'active' devices
      if [ ${active} -eq 1 ]; then
        if [ ${guest} -eq 1 ]; then
          maclist_guest+=(${mac^^}) # add uppercased mac address
          iplist_guest+=(${ipaddr})
        else
          maclist_normal+=(${mac^^}) # add uppercased mac address
          iplist_normal+=(${ipaddr})
        fi
      fi

      # reset variables
      name=""
      ipaddr=""
      mac=""
      guest=0
      active=0
    fi
  done <<< "${devices}"

  # modify the global associative array for the normal-WiFi
  for (( i = 0; i < ${#maclist_normal[@]} ; i++ )); do
    normalDeviceList[${maclist_normal[$i]}]=${iplist_normal[$i]}
  done

  # modify the global associative array for the guest-WiFi
  for (( i = 0; i < ${#maclist_guest[@]} ; i++ )); do
    guestDeviceList[${maclist_guest[$i]}]=${iplist_guest[$i]}
  done
}

# function that creates a list of tupels from an input string
# of individual users. This tuple list can then be used to be set for the
# presence.list variable type when constructing it
function createUserTupleList()
{
  local a="$1"

  # constract the brace expansion string from the input
  # string so that we end up with something like '{1,}{2,}{3,}', etc.
  local b=""
  local i=0
  for Y in $a; do
    ((i = i + 1))
    b=$b{$i,}
  done

  # lets apply the brace expansion string and sort it
  # according to numbers and not have it in the standard sorting
  local c=$(for X in $(eval echo\ $b); do echo $X; done | sort -n)

  # lets construct tupels for every number (1-9) in
  # the brace expansion
  local tuples=""
  for X in $c; do
    if [ -n "${tuples}" ]; then
      tuples="${tuples};"
    fi
    folded=$(echo ${X} | fold -w1)
    tuples="${tuples}$(echo ${folded} | tr ' ' ',')"
  done

  # now we replace each number (1-9) with the appropriate
  # string of the input array
  local i=0
  for Z in ${a}; do
    ((i = i + 1))
    tuples=${tuples//${i}/${Z}}
  done

  # now add Guest to each tuple
  IFS=';'
  local guestTuples="${HM_CCU_PRESENCE_GUEST}"
  for U in ${tuples}; do
    guestTuples="${guestTuples};${U},${HM_CCU_PRESENCE_GUEST}"
  done
  IFS=' '

  tuples="${HM_CCU_PRESENCE_NOBODY};${tuples};${guestTuples}"

  echo "${tuples}"
}

# function to count the position within the enum list
# where the presence list matches
function whichEnumID()
{
  local enumList="$1"
  local presenceList="$2"

  # now we iterate through the ;—separated enumList
  IFS=';'
  local i=0
  local result=0
  for id in ${enumList}; do
    if [ "${presenceList}" == "${id}" ]; then
      result=$i
      break
    fi
    ((i = i + 1 ))
  done
  IFS=' '

  echo ${result}
}

################################################
# main processing starts here
#

echo "hm_pdetect 0.7 - a FRITZ!-based HomeMatic presence detection script"
echo "(Jan 27 2016) Copyright (C) 2015-2016 Jens Maus <mail@jens-maus.de>"
echo


# lets retrieve all mac<>ip addresses of currently
# active devices in our network
echo -n "Querying FRITZ! devices:"
i=0
for ip in ${HM_FRITZ_IP[@]}; do
  echo -n " ${ip}"
  retrieveFritzBoxDeviceList ${ip} ${HM_FRITZ_USER} ${HM_FRITZ_SECRET}
  if [ $? -eq 0 ]; then
    ((i = i + 1))
  fi
done

# check that we were able to connect to at least one device
if [ ${i} -eq 0 ]; then
  echo "ERROR: couldn't connect to any specified FRITZ! device."
  exit ${RETURN_FAILUE}
fi

# output some statistics
echo
echo " Normal-WiFi devices active: ${#normalDeviceList[@]}"
echo " Guest-WiFi devices active: ${#guestDeviceList[@]}"

# lets identify user presence
presenceList=""
echo "Checking user presence: "
for user in "${!HM_USER_LIST[@]}"; do
  echo -n " ${user}: "
  stat="false"

  # prepare the device list of the user as a regex
  userDeviceList=$(echo ${HM_USER_LIST[${user}]} | tr ' ' '|')

  # match MAC address and IP address in normal and guest WiFi
  if [[ ${normalDeviceList[@]}  =~ ${userDeviceList^^} ]] || \
     [[ ${guestDeviceList[@]}   =~ ${userDeviceList^^} ]] || \
     [[ ${!normalDeviceList[@]} =~ ${userDeviceList^^} ]] || \
     [[ ${!guestDeviceList[@]}  =~ ${userDeviceList^^} ]]; then
    stat="true"
  fi

  if [ "${stat}" == "true" ]; then
    echo present
    if [ -n "${presenceList}" ]; then
      presenceList+=","
    fi
    presenceList+=${user}
  else
    echo away
  fi

  # remove checked user devices from deviceList so that
  # they are not recognized as guest devices
  for device in ${HM_USER_LIST[${user}]}; do
    # try to match MAC address first
    if [[ ${!normalDeviceList[@]} =~ ${device^^} ]]; then
      unset normalDeviceList[${device^^}]
    elif [[ ${!guestDeviceList[@]} =~ ${device^^} ]]; then
      unset guestDeviceList[${device^^}]
    else
      # now match the IP address list instead
      if [[ ${normalDeviceList[@]} =~ ${device^^} ]]; then
        for dev in ${!normalDeviceList[@]}; do
          if [ ${normalDeviceList[${dev}]} == ${device^^} ]; then
            unset normalDeviceList[${dev}]
            break
          fi
        done
      elif [[ ${guestDeviceList[@]} =~ ${device^^} ]]; then
        for dev in ${!guestDeviceList[@]}; do
          if [ ${guestDeviceList[${dev}]} == ${device^^} ]; then
            unset guestDeviceList[${dev}]
            break
          fi
        done
      fi
    fi
  done

  # set status in homematic CCU
  createVariable ${HM_CCU_PRESENCE_VAR}.${user} bool "${user} @ home"
  setVariableState ${HM_CCU_PRESENCE_VAR}.${user} ${stat}

done

# lets identify guests by checking the normal and guest
# wifi device list and comparing them to the HM_KNOWN_LIST
HM_KNOWN_LIST=( ${HM_KNOWN_LIST[@]^^} ) # uppercase array
for device in ${HM_KNOWN_LIST[@]}; do

  # try to match MAC address first
  if [[ ${!normalDeviceList[@]} =~ ${device} ]]; then
    unset normalDeviceList[${device}]
  elif [[ ${!guestDeviceList[@]} =~ ${device} ]]; then
    unset guestDeviceList[${device}]
  else
    # now match the IP address list instead
    if [[ ${normalDeviceList[@]} =~ ${device} ]]; then
      for dev in ${!normalDeviceList[@]}; do
        if [ ${normalDeviceList[${dev}]} == ${device} ]; then
          unset normalDeviceList[${dev}]
          break
        fi
      done
    elif [[ ${guestDeviceList[@]} =~ ${device} ]]; then
      for dev in ${!guestDeviceList[@]}; do
        if [ ${guestDeviceList[${dev}]} == ${device} ]; then
          unset guestDeviceList[${dev}]
          break
        fi
      done
    fi
  fi

done

# depending on the HM_KNOWN_LIST_MODE mode we populate the guestList
# with devices from the normalDeviceList and guestDeviceList or
# just from the guestDeviceList
guestList=()
if [ ${HM_KNOWN_LIST_MODE} != "guest" ]; then
  for device in ${!normalDeviceList[@]}; do
    guestList+=(${device})
  done
fi
for device in ${!guestDeviceList[@]}; do
  guestList+=(${device})
done

echo "Checking guest presence: "
# create/set presence system variable in CCU if guest devices
# were found
echo -n " ${HM_CCU_PRESENCE_GUEST}: "
if [ ${#guestList[@]} -gt 0 ]; then
  # set status in homematic CCU
  echo "present - ${#guestList[@]} (${guestList[@]})"
  createVariable ${HM_CCU_PRESENCE_VAR}.${HM_CCU_PRESENCE_GUEST} bool "${HM_CCU_PRESENCE_GUEST} @ home"
  setVariableState ${HM_CCU_PRESENCE_VAR}.${HM_CCU_PRESENCE_GUEST} true
  if [ -n "${presenceList}" ]; then
    presenceList+=","
  fi
  presenceList+="${HM_CCU_PRESENCE_GUEST}"
else
  echo "away"
  createVariable ${HM_CCU_PRESENCE_VAR}.${HM_CCU_PRESENCE_GUEST} bool "${HM_CCU_PRESENCE_GUEST} @ home"
  setVariableState ${HM_CCU_PRESENCE_VAR}.${HM_CCU_PRESENCE_GUEST} false
fi

# we create and set another global presence variable as an
# enum of all possible presence combinations
if [ -n "${HM_CCU_PRESENCE_VAR_LIST}" ]; then
  userList="${!HM_USER_LIST[@]}"
  userTupleList=$(createUserTupleList "${userList}")
  createVariable ${HM_CCU_PRESENCE_VAR_LIST} enum "presence enum list @ home" ${userTupleList}
  setVariableState ${HM_CCU_PRESENCE_VAR_LIST} $(whichEnumID ${userTupleList} ${presenceList})
fi

# we create and set a global presence variable as a string
# variable which users can query.
if [ -n "${HM_CCU_PRESENCE_VAR_STR}" ]; then
  if [ -z "${presenceList}" ]; then
    userList="${HM_CCU_PRESENCE_NOBODY}"
  else
    userList="${presenceList}"
  fi
  createVariable ${HM_CCU_PRESENCE_VAR_STR} string "presence list @ home"
  setVariableState ${HM_CCU_PRESENCE_VAR_STR} \'${userList}\'
fi

# set the global presence variable to true/false depending
# on the general presence of people in the house
createVariable ${HM_CCU_PRESENCE_VAR} bool "global presence @ home"
if [ -z "${presenceList}" ]; then
  setVariableState ${HM_CCU_PRESENCE_VAR} false
else
  setVariableState ${HM_CCU_PRESENCE_VAR} true
fi

exit ${RETURN_SUCCESS}
