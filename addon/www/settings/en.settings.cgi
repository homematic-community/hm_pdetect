#!/usr/bin/env tclsh
source [file join [file dirname [info script]] inc/settings.tcl]
parseQuery
if { $args(command) == "defaults" } {
    set args(cc) "49"
    set args(phone) ""
    set args(id) ""
    set args(password) ""
    set args(cc_note) "Country code"
    set args(phone_note) "Phone number"
    set args(id_note) "don't fill"
    set args(password_note) "don't fill at first"
    set args(command) "save"
} 
if { $args(command) == "save" } {
	saveConfigFile
	catch { close [open "|/etc/config/rc.d/$ADDONNAME restart"] }
} 

set cc "49"
set phone ""
set id ""
set password ""
set cc_note "Country code"
set phone_note "Phone number"
set id_note "don't fill"
set password_note "don't fill at first"

loadConfigFile
set content [loadFile en.settings.html]
source [file join [file dirname [info script]] inc/settings1.tcl]
