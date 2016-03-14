regsub -all {<%HM_FRITZ_IP%>} $content [string trim $HM_FRITZ_IP] content
regsub -all {<%HM_FRITZ_USER%>} $content [string trim $HM_FRITZ_USER] content
regsub -all {<%HM_FRITZ_SECRET%>} $content [string trim $HM_FRITZ_SECRET] content
regsub -all {<%HM_CCU_PRESENCE_VAR%>} $content [string trim $HM_CCU_PRESENCE_VAR] content
regsub -all {<%HM_CCU_PRESENCE_LIST%>} $content [string trim $HM_CCU_PRESENCE_LIST] content
regsub -all {<%HM_CCU_PRESENCE_STR%>} $content [string trim $HM_CCU_PRESENCE_STR] content
regsub -all {<%HM_CCU_PRESENCE_GUEST%>} $content [string trim $HM_CCU_PRESENCE_GUEST] content
regsub -all {<%HM_CCU_PRESENCE_NOBODY%>} $content [string trim $HM_CCU_PRESENCE_NOBODY] content
regsub -all {<%HM_CCU_PRESENCE_USER%>} $content [string trim $HM_CCU_PRESENCE_USER] content
regsub -all {<%HM_CCU_PRESENCE_PRESENT%>} $content [string trim $HM_CCU_PRESENCE_PRESENT] content
regsub -all {<%HM_CCU_PRESENCE_AWAY%>} $content [string trim $HM_CCU_PRESENCE_AWAY] content
regsub -all {<%HM_USER_LIST%>} $content [string trim $HM_USER_LIST] content
regsub -all {<%HM_KNOWN_LIST%>} $content [string trim $HM_KNOWN_LIST] content
regsub -all {<%HM_INTERVAL_TIME%>} $content [string trim $HM_INTERVAL_TIME] content

if {[string equal "all" $HM_KNOWN_LIST_MODE]} {
  set HM_KNOWN_LIST_MODE1 ""
  set HM_KNOWN_LIST_MODE2 "checked"
  set HM_KNOWN_LIST_MODE3 ""
} elseif {[string equal "off" $HM_KNOWN_LIST_MODE]} {
  set HM_KNOWN_LIST_MODE1 ""
  set HM_KNOWN_LIST_MODE2 ""
  set HM_KNOWN_LIST_MODE3 "checked"
} else {
  set HM_KNOWN_LIST_MODE1 "checked"
  set HM_KNOWN_LIST_MODE2 ""
  set HM_KNOWN_LIST_MODE3 ""
}

regsub -all {<%HM_KNOWN_LIST_MODE1%>} $content [string trim $HM_KNOWN_LIST_MODE1] content
regsub -all {<%HM_KNOWN_LIST_MODE2%>} $content [string trim $HM_KNOWN_LIST_MODE2] content
regsub -all {<%HM_KNOWN_LIST_MODE3%>} $content [string trim $HM_KNOWN_LIST_MODE3] content

if {[string equal "false" $HM_CCU_PRESENCE_LIST_ENABLED]} {
  set HM_CCU_PRESENCE_LIST_ENABLED ""
} else {
  set HM_CCU_PRESENCE_LIST_ENABLED "checked"
}
regsub -all {<%HM_CCU_PRESENCE_LIST_ENABLED%>} $content [string trim $HM_CCU_PRESENCE_LIST_ENABLED] content

if {[string equal "false" $HM_CCU_PRESENCE_STR_ENABLED]} {
  set HM_CCU_PRESENCE_STR_ENABLED ""
} else {
  set HM_CCU_PRESENCE_STR_ENABLED "checked"
}
regsub -all {<%HM_CCU_PRESENCE_STR_ENABLED%>} $content [string trim $HM_CCU_PRESENCE_STR_ENABLED] content

if {[string equal "false" $HM_CCU_PRESENCE_GUEST_ENABLED]} {
  set HM_CCU_PRESENCE_GUEST_ENABLED ""
} else {
  set HM_CCU_PRESENCE_GUEST_ENABLED "checked"
}
regsub -all {<%HM_CCU_PRESENCE_GUEST_ENABLED%>} $content [string trim $HM_CCU_PRESENCE_GUEST_ENABLED] content

if {[string equal "false" $HM_CCU_PRESENCE_USER_ENABLED]} {
  set HM_CCU_PRESENCE_USER_ENABLED ""
} else {
  set HM_CCU_PRESENCE_USER_ENABLED "checked"
}
regsub -all {<%HM_CCU_PRESENCE_USER_ENABLED%>} $content [string trim $HM_CCU_PRESENCE_USER_ENABLED] content

puts "Content-Type: text/html; charset=utf-8\n\n"
puts $content
