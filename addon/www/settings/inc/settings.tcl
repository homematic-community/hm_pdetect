set ADDONNAME "hm_pdetect"
set FILENAME "/usr/local/addons/hm_pdetect/etc/hm_pdetect.conf"

array set args { command INV HM_FRITZ_IP {} HM_FRITZ_USER {} HM_FRITZ_SECRET {} HM_CCU_PRESENCE_VAR {} HM_CCU_PRESENCE_LIST {} HM_CCU_PRESENCE_STR {} HM_CCU_PRESENCE_GUEST {} HM_CCU_PRESENCE_NOBODY {} HM_CCU_PRESENCE_USER {} HM_CCU_PRESENCE_PRESENT {} HM_CCU_PRESENCE_AWAY {} HM_USER_LIST {} HM_KNOWN_LIST_MODE {} HM_KNOWN_LIST {} HM_INTERVAL_TIME {} }

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

proc str-escape str {
    set str [string map -nocase { 
              "\"" "\\\""
              "\$" "\\\$"
              "\\" "\\\\"
              "`"  "\\`"
             } $str]

    return $str
}

proc str-unescape str {
    set str [string map -nocase { 
              "\\\"" "\""
              "\\\$" "\$"
              "\\\\" "\\"
              "\\`"  "`"
             } $str]

    return $str
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
    global FILENAME HM_FRITZ_IP HM_FRITZ_USER HM_FRITZ_SECRET HM_CCU_PRESENCE_VAR HM_CCU_PRESENCE_LIST HM_CCU_PRESENCE_STR HM_CCU_PRESENCE_GUEST HM_CCU_PRESENCE_NOBODY HM_CCU_PRESENCE_USER HM_CCU_PRESENCE_PRESENT HM_CCU_PRESENCE_AWAY HM_USER_LIST HM_KNOWN_LIST_MODE HM_KNOWN_LIST HM_INTERVAL_TIME
    set conf ""
    catch {set conf [loadFile $FILENAME]}

    if { [string trim "$conf"] != "" } {
        set HM_INTERVAL_MAX 0

        regexp -line {^HM_FRITZ_IP=\"(.*)\"$} $conf dummy HM_FRITZ_IP
        regexp -line {^HM_FRITZ_USER=\"(.*)\"$} $conf dummy HM_FRITZ_USER
        regexp -line {^HM_FRITZ_SECRET=\"(.*)\"$} $conf dummy HM_FRITZ_SECRET
        regexp -line {^HM_CCU_PRESENCE_VAR=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_VAR
        regexp -line {^HM_CCU_PRESENCE_LIST=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_LIST
        regexp -line {^HM_CCU_PRESENCE_STR=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_STR
        regexp -line {^HM_CCU_PRESENCE_GUEST=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_GUEST
        regexp -line {^HM_CCU_PRESENCE_NOBODY=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_NOBODY
        regexp -line {^HM_CCU_PRESENCE_USER=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_USER
        regexp -line {^HM_CCU_PRESENCE_PRESENT=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_PRESENT
        regexp -line {^HM_CCU_PRESENCE_AWAY=\"(.*)\"$} $conf dummy HM_CCU_PRESENCE_AWAY
        regexp -line {^HM_USER_LIST=\((.*)\)$} $conf dummy HM_USER_LIST
        regexp -line {^HM_KNOWN_LIST_MODE=\"(.*)\"$} $conf dummy HM_KNOWN_LIST_MODE
        regexp -line {^HM_KNOWN_LIST=\"(.*)\"$} $conf dummy HM_KNOWN_LIST
        regexp -line {^HM_INTERVAL_MAX=\"(.*)\"$} $conf dummy HM_INTERVAL_MAX
        regexp -line {^HM_INTERVAL_TIME=\"(.*)\"$} $conf dummy HM_INTERVAL_TIME

        # if HM_INTERVAL_MAX is 1 we have to uncheck the
        # checkbox to signal that the interval stuff is disabled.
        if { $HM_INTERVAL_MAX == 1 } {
          set HM_INTERVAL_TIME 0
        }
 
        # lets replace all spaces with newlines for the
        # textarea fields in the html code.
        regsub -all {\s+} $HM_KNOWN_LIST "\n" HM_KNOWN_LIST
        regsub -all {\s+\[} $HM_USER_LIST "\n\[" HM_USER_LIST

        # make sure to unescape variable content that was properly escaped
        # due to shell variable regulations
        set HM_FRITZ_USER [str-unescape $HM_FRITZ_USER]
        set HM_FRITZ_SECRET [str-unescape $HM_FRITZ_SECRET]
    }
}

proc saveConfigFile { } {
    global FILENAME args
        
    set fd [open $FILENAME w]

    set HM_FRITZ_IP [url-decode $args(HM_FRITZ_IP)]
    set HM_FRITZ_USER [url-decode $args(HM_FRITZ_USER)]
    set HM_FRITZ_SECRET [url-decode $args(HM_FRITZ_SECRET)]
    set HM_CCU_PRESENCE_VAR [url-decode $args(HM_CCU_PRESENCE_VAR)]
    set HM_CCU_PRESENCE_LIST [url-decode $args(HM_CCU_PRESENCE_LIST)]
    set HM_CCU_PRESENCE_STR [url-decode $args(HM_CCU_PRESENCE_STR)]
    set HM_CCU_PRESENCE_GUEST [url-decode $args(HM_CCU_PRESENCE_GUEST)]
    set HM_CCU_PRESENCE_NOBODY [url-decode $args(HM_CCU_PRESENCE_NOBODY)]
    set HM_CCU_PRESENCE_USER [url-decode $args(HM_CCU_PRESENCE_USER)]
    set HM_CCU_PRESENCE_PRESENT [url-decode $args(HM_CCU_PRESENCE_PRESENT)]
    set HM_CCU_PRESENCE_AWAY [url-decode $args(HM_CCU_PRESENCE_AWAY)]
    set HM_USER_LIST [url-decode $args(HM_USER_LIST)]
    set HM_KNOWN_LIST_MODE [url-decode $args(HM_KNOWN_LIST_MODE)]
    set HM_KNOWN_LIST [url-decode $args(HM_KNOWN_LIST)]
    set HM_INTERVAL_TIME [url-decode $args(HM_INTERVAL_TIME)]

    # make sure to replace newline stuff and double whitespaces with single whitespaces
    # because in the config we don't allow newlines.
    regsub -all {\s+} $HM_USER_LIST " " HM_USER_LIST
    regsub -all {\s+} $HM_KNOWN_LIST " " HM_KNOWN_LIST

    # make sure to escape variable content that may contain special
    # characters not allowed unescaped in shell variables.
    set HM_FRITZ_USER [str-escape $HM_FRITZ_USER]
    set HM_FRITZ_SECRET [str-escape $HM_FRITZ_SECRET]
    
    # we set config options that should not be changeable on the CCU
    puts $fd "HM_CCU_IP=127.0.0.1"
    puts $fd "HM_PROCESSLOG_FILE=\"/var/log/hm_pdetect.log\""
    puts $fd "HM_DAEMON_PIDFILE=\"/var/run/hm_pdetect.pid\""

    # only add the following variables if they are NOT empty
    if { [string length $HM_FRITZ_IP] > 0 }              { puts $fd "HM_FRITZ_IP=\"$HM_FRITZ_IP\"" }
    if { [string length $HM_FRITZ_USER] > 0 }            { puts $fd "HM_FRITZ_USER=\"$HM_FRITZ_USER\"" }
    if { [string length $HM_FRITZ_SECRET] > 0 }          { puts $fd "HM_FRITZ_SECRET=\"$HM_FRITZ_SECRET\"" }
    if { [string length $HM_CCU_PRESENCE_VAR] > 0 }      { puts $fd "HM_CCU_PRESENCE_VAR=\"$HM_CCU_PRESENCE_VAR\"" }
    if { [string length $HM_CCU_PRESENCE_LIST] > 0 }     { puts $fd "HM_CCU_PRESENCE_LIST=\"$HM_CCU_PRESENCE_LIST\"" }
    if { [string length $HM_CCU_PRESENCE_STR] > 0 }      { puts $fd "HM_CCU_PRESENCE_STR=\"$HM_CCU_PRESENCE_STR\"" }
    if { [string length $HM_CCU_PRESENCE_GUEST] > 0 }    { puts $fd "HM_CCU_PRESENCE_GUEST=\"$HM_CCU_PRESENCE_GUEST\"" }
    if { [string length $HM_CCU_PRESENCE_NOBODY] > 0 }   { puts $fd "HM_CCU_PRESENCE_NOBODY=\"$HM_CCU_PRESENCE_NOBODY\"" }
    if { [string length $HM_CCU_PRESENCE_USER] > 0 }     { puts $fd "HM_CCU_PRESENCE_USER=\"$HM_CCU_PRESENCE_USER\"" }
    if { [string length $HM_CCU_PRESENCE_PRESENT] > 0 }  { puts $fd "HM_CCU_PRESENCE_PRESENT=\"$HM_CCU_PRESENCE_PRESENT\"" }
    if { [string length $HM_CCU_PRESENCE_AWAY] > 0 }     { puts $fd "HM_CCU_PRESENCE_AWAY=\"$HM_CCU_PRESENCE_AWAY\"" }
    if { [string length $HM_KNOWN_LIST_MODE] > 0 }       { puts $fd "HM_KNOWN_LIST_MODE=\"$HM_KNOWN_LIST_MODE\"" }

    if { $HM_INTERVAL_TIME == 0 } { 
      puts $fd "HM_INTERVAL_MAX=\"1\""
    } else {
      puts $fd "HM_INTERVAL_TIME=\"$HM_INTERVAL_TIME\""
    }

    # also add empty variables on purpose
    puts $fd "HM_USER_LIST=($HM_USER_LIST)"
    puts $fd "HM_KNOWN_LIST=\"$HM_KNOWN_LIST\""
    
    close $fd

    # we have updated our configuration so lets
    # stop/restart hm_pdetect
    if { $HM_INTERVAL_TIME == 0 } { 
      exec /usr/local/etc/config/rc.d/hm_pdetect stop &
    } else {
      exec /usr/local/etc/config/rc.d/hm_pdetect restart &
    }
}
