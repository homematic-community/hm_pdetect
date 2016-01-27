#!/usr/bin/env tclsh
source [file join [file dirname [info script]] inc/settings.tcl]

set content [loadFile logoutput.html]
set HM_LOGOUTPUT [loadFile /var/log/hm_pdetect.log]

regsub -all {<%HM_LOGOUTPUT%>} $content [string trim $HM_LOGOUTPUT] content

puts "Content-type:text/html\n\n"
puts $content
