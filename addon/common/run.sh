#!/bin/sh
export PATH=/usr/local/addons/hm_pdetect/bin:${PATH}
/usr/local/addons/hm_pdetect/bin/hm_pdetect.sh /usr/local/addons/hm_pdetect/etc/hm_pdetect.conf 2>&1 >/var/log/hm_pdetect.log
