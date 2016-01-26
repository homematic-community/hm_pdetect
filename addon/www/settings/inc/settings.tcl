set ADDONNAME "hm_pdetect"
set FILENAME "/usr/local/addons/hm_pdetect/etc/hm_pdetect.conf"

array set args { command INV HM_FRITZ_IP {} HM_FRITZ_USER {} HM_FRITZ_SECRET {} HM_CCU_IP {} HM_CCU_PRESENCE_VAR {} HM_CCU_PRESENCE_VAR_LIST {} HM_CCU_PRESENCE_VAR_STR {} HM_CCU_PRESENCE_GUEST {} HM_CCU_PRESENCE_NOBODY {} HM_CCU_PRESENCE_PRESENT {} HM_CCU_PRESENCE_AWAY {} HM_USER_LIST {} HM_KNOWN_LIST_MODE {} HM_KNOWN_LIST {} }

proc utf8 {hex} {
    set hex [string map {% {}} $hex]
    return [encoding convertfrom utf-8 [binary format H* $hex]]
}

proc url-decode str {
    # rewrite "+" back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\" "\[" "\\\["] $str]

    # Replace UTF-8 sequences with calls to the utf8 decode proc...
    regsub -all {(%[0-9A-Fa-f0-9]{2})+} $str {[utf8 \0]} str

    # process \u unicode mapped chars
    return [subst -novar  $str]
}
proc parseQuery { } {
    global args env
    
    set query [array names env]
    if { [info exists env(QUERY_STRING)] } {
        set query $env(QUERY_STRING)
    }
    
    foreach item [split $query &] {
        if { [regexp {([^=]+)=(.+)} $item dummy key value] } {
            set args($key) $value
        }
    }
}


proc loadFile { fileName } {
    set content ""
    set fd -1
    
    set fd [ open $fileName r]
    if { $fd > -1 } {
        set content [read $fd]
        close $fd
    }
    
    return $content
}

proc loadConfigFile { } {
    global FILENAME HM_FRITZ_IP HM_FRITZ_USER HM_FRITZ_SECRET HM_CCU_IP HM_CCU_PRESENCE_VAR HM_CCU_PRESENCE_VAR_LIST HM_CCU_PRESENCE_VAR_STR HM_CCU_PRESENCE_GUEST HM_CCU_PRESENCE_NOBODY HM_CCU_PRESENCE_PRESENT HM_CCU_PRESENCE_AWAY HM_USER_LIST HM_KNOWN_LIST_MODE HM_KNOWN_LIST
    set conf ""
    catch {set conf [loadFile $FILENAME]}

    if { [string trim "$conf"] != "" } {
        regexp -line {^HM_FRITZ_IP=\"(.*)\"$} $conf dummy HM_FRITZ_IP
        regexp -line {^HM_FRITZ_USER=\"(.*)\"$} $conf dummy HM_FRITZ_USER
        regexp -line {^HM_FRITZ_SECRET=\"(.*)\"$} $conf dummy HM_FRITZ_SECRET
        regexp -line {^HM_CCU_IP=\"(.*)\"$} $conf dummy HM_CCU_IP
        regexp -line {^HM_CCU_PRESENCE_VAR=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_VAR
        regexp -line {^HM_CCU_PRESENCE_VAR_LIST=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_VAR_LIST
        regexp -line {^HM_CCU_PRESENCE_VAR_STR=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_VAR_STR
        regexp -line {^HM_CCU_PRESENCE_GUEST=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_GUEST
        regexp -line {^HM_CCU_PRESENCE_NOBODY=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_NOBODY
        regexp -line {^HM_CCU_PRESENCE_PRESENT=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_PRESENT
        regexp -line {^HM_CCU_PRESENCE_AWAY=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_AWAY
        regexp -line {^HM_USER_LIST=\((.*)\)$} $conf dummy HM_USER_LIST
        regexp -line {^HM_KNOWN_LIST_MODE=\"(.*)\"$} $conf dummy HM_KNOWN_LIST_MODE
        regexp -line {^HM_KNOWN_LIST=\"(.*)\"$} $conf dummy HM_KNOWN_LIST

        # lets replace all spaces with newlines
        regsub -all {\s+} $HM_KNOWN_LIST "\n" HM_KNOWN_LIST
        regsub -all {\s+\[} $HM_USER_LIST "\n\[" HM_USER_LIST
    }
}

proc saveConfigFile { } {
    global FILENAME args
        
    set fd [open $FILENAME w]

    set HM_FRITZ_IP [url-decode $args(HM_FRITZ_IP)]
    set HM_FRITZ_USER [url-decode $args(HM_FRITZ_USER)]
    set HM_FRITZ_SECRET [url-decode $args(HM_FRITZ_SECRET)]
    set HM_CCU_IP [url-decode $args(HM_CCU_IP)]
    set HM_CCU_PRESENCE_VAR [url-decode $args(HM_CCU_PRESENCE_VAR)]
    set HM_CCU_PRESENCE_VAR_LIST [url-decode $args(HM_CCU_PRESENCE_VAR_LIST)]
    set HM_CCU_PRESENCE_VAR_STR [url-decode $args(HM_CCU_PRESENCE_VAR_STR)]
    set HM_CCU_PRESENCE_GUEST [url-decode $args(HM_CCU_PRESENCE_GUEST)]
    set HM_CCU_PRESENCE_NOBODY [url-decode $args(HM_CCU_PRESENCE_NOBODY)]
    set HM_CCU_PRESENCE_PRESENT [url-decode $args(HM_CCU_PRESENCE_PRESENT)]
    set HM_CCU_PRESENCE_AWAY [url-decode $args(HM_CCU_PRESENCE_AWAY)]
    set HM_USER_LIST [url-decode $args(HM_USER_LIST)]
    set HM_KNOWN_LIST_MODE [url-decode $args(HM_KNOWN_LIST_MODE)]
    set HM_KNOWN_LIST [url-decode $args(HM_KNOWN_LIST)]

    # make sure to replace newline stuff and double whitespaces with single whitespaces
    regsub -all {\s+} $HM_USER_LIST " " HM_USER_LIST
    regsub -all {\s+} $HM_KNOWN_LIST " " HM_KNOWN_LIST
    
    puts $fd [url-decode "HM_CCU_IP=127.0.0.1"]
    if { [string length $HM_FRITZ_IP] > 0 }              { puts $fd "HM_FRITZ_IP=\"$HM_FRITZ_IP\"" }
    if { [string length $HM_FRITZ_USER] > 0 }            { puts $fd "HM_FRITZ_USER=\"$HM_FRITZ_USER\"" }
    if { [string length $HM_FRITZ_SECRET] > 0 }          { puts $fd "HM_FRITZ_SECRET=\"$HM_FRITZ_SECRET\"" }
    if { [string length $HM_CCU_PRESENCE_VAR] > 0 }      { puts $fd "HM_CCU_PRESENCE_VAR=\"$HM_CCU_PRESENCE_VAR\"" }
    if { [string length $HM_CCU_PRESENCE_VAR_LIST] > 0 } { puts $fd "HM_CCU_PRESENCE_VAR_LIST=\"$HM_CCU_PRESENCE_VAR_LIST\"" }
    if { [string length $HM_CCU_PRESENCE_VAR_STR] > 0 }  { puts $fd "HM_CCU_PRESENCE_VAR_STR=\"$HM_CCU_PRESENCE_VAR_STR\"" }
    if { [string length $HM_CCU_PRESENCE_GUEST] > 0 }    { puts $fd "HM_CCU_PRESENCE_GUEST=\"$HM_CCU_PRESENCE_GUEST\"" }
    if { [string length $HM_CCU_PRESENCE_NOBODY] > 0 }   { puts $fd "HM_CCU_PRESENCE_NOBODY=\"$HM_CCU_PRESENCE_NOBODY\"" }
    if { [string length $HM_CCU_PRESENCE_PRESENT] > 0 }  { puts $fd "HM_CCU_PRESENCE_PRESENT=\"$HM_CCU_PRESENCE_PRESENT\"" }
    if { [string length $HM_CCU_PRESENCE_AWAY] > 0 }     { puts $fd "HM_CCU_PRESENCE_AWAY=\"$HM_CCU_PRESENCE_AWAY\"" }
    if { [string length $HM_KNOWN_LIST_MODE] > 0 }       { puts $fd "HM_KNOWN_LIST_MODE=\"$HM_KNOWN_LIST_MODE\"" }
    puts $fd "HM_USER_LIST=($HM_USER_LIST)"
    puts $fd "HM_KNOWN_LIST=\"$HM_KNOWN_LIST\""
    
    close $fd
}
