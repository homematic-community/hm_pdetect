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
        regexp -line {^HM_FRITZ_IP=(.*)$} $conf HM_FRITZ_IP
        regexp -line {^HM_FRITZ_USER=(.*)$} $conf HM_FRITZ_USER
        regexp -line {^HM_FRITZ_SECRET=(.*)$} $conf HM_FRITZ_SECRET
        regexp -line {^HM_CCU_IP=(.*)$} $conf HM_CCU_IP
        regexp -line {^HM_CCU_PRESENCE_VAR=(.*)$} $conf HM_CCU_PRESENCE_VAR
        regexp -line {^HM_CCU_PRESENCE_VAR_LIST=(.*)$} $conf HM_CCU_PRESENCE_VAR_LIST
        regexp -line {^HM_CCU_PRESENCE_VAR_STR=(.*)$} $conf HM_CCU_PRESENCE_VAR_STR
        regexp -line {^HM_CCU_PRESENCE_GUEST=(.*)$} $conf HM_CCU_PRESENCE_GUEST
        regexp -line {^HM_CCU_PRESENCE_NOBODY=(.*)$} $conf HM_CCU_PRESENCE_NOBODY
        regexp -line {^HM_CCU_PRESENCE_PRESENT=(.*)$} $conf HM_CCU_PRESENCE_PRESENT
        regexp -line {^HM_CCU_PRESENCE_AWAY=(.*)$} $conf HM_CCU_PRESENCE_AWAY
        regexp -line {^HM_USER_LIST=\((.*)\)$} $conf HM_USER_LIST
        regexp -line {^HM_KNOWN_LIST_MODE=(.*)$} $conf HM_KNOWN_LIST_MODE
        regexp -line {^HM_KNOWN_LIST=(.*)$} $conf HM_KNOWN_LIST
    }
}

proc saveConfigFile { } {
    global FILENAME args
        
    set fd [open $FILENAME w]

    set HM_FRITZ_IP $args(HM_FRITZ_IP)
    set HM_FRITZ_USER $args(HM_FRITZ_USER)
    set HM_FRITZ_SECRET $args(HM_FRITZ_SECRET)
    set HM_CCU_IP $args(HM_CCU_IP)
    set HM_CCU_PRESENCE_VAR $args(HM_CCU_PRESENCE_VAR)
    set HM_CCU_PRESENCE_VAR_LIST $args(HM_CCU_PRESENCE_VAR_LIST)
    set HM_CCU_PRESENCE_VAR_STR $args(HM_CCU_PRESENCE_VAR_STR)
    set HM_CCU_PRESENCE_GUEST $args(HM_CCU_PRESENCE_GUEST)
    set HM_CCU_PRESENCE_NOBODY $args(HM_CCU_PRESENCE_NOBODY)
    set HM_CCU_PRESENCE_PRESENT $args(HM_CCU_PRESENCE_PRESENT)
    set HM_CCU_PRESENCE_AWAY $args(HM_CCU_PRESENCE_AWAY)
    set HM_USER_LIST $args(HM_USER_LIST)
    set HM_KNOWN_LIST_MODE $args(HM_KNOWN_LIST_MODE)
    set HM_KNOWN_LIST $args(HM_KNOWN_LIST)
    
    puts $fd "HM_FRITZ_IP=$HM_FRITZ_IP"
    puts $fd "HM_FRITZ_USER=$HM_FRITZ_USER"
    puts $fd "HM_FRITZ_SECRET=$HM_FRITZ_SECRET"
    puts $fd "HM_CCU_IP=$HM_CCU_IP"
    puts $fd "HM_CCU_PRESENCE_VAR=$HM_CCU_PRESENCE_VAR"
    puts $fd "HM_CCU_PRESENCE_VAR_LIST=$HM_CCU_PRESENCE_VAR_LIST"
    puts $fd "HM_CCU_PRESENCE_VAR_STR=$HM_CCU_PRESENCE_VAR_STR"
    puts $fd "HM_CCU_PRESENCE_GUEST=$HM_CCU_PRESENCE_GUEST"
    puts $fd "HM_CCU_PRESENCE_NOBODY=$HM_CCU_PRESENCE_NOBODY"
    puts $fd "HM_CCU_PRESENCE_PRESENT=$HM_CCU_PRESENCE_PRESENT"
    puts $fd "HM_CCU_PRESENCE_AWAY=$HM_CCU_PRESENCE_AWAY"
    puts $fd "HM_USER_LIST=($HM_USER_LIST)"
    puts $fd "HM_KNOWN_LIST_MODE=($HM_KNOWN_LIST_MODE)"
    puts $fd "HM_KNOWN_LIST=$HM_KNOWN_LIST"
    
    close $fd
}
