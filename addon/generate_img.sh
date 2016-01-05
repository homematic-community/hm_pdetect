#!/bin/bash
#
# script to generate the CCU addon package.

# generate tempdir
mkdir -p tmp
rm -rf tmp/*

# copy all relevant stuff
cp -a update_script tmp/
cp -a common tmp/
cp -a rc.d tmp/
cp -a www tmp/
cp -a ../VERSION tmp/www/
cp -a ccu1 tmp/
cp -a ccu2 tmp/
cp -a ccurm tmp/

# copy hm_pdetect main script + config
mkdir -p tmp/common/bin
cp -a ../hm_pdetect.sh tmp/common/bin/

# generate archive
cd tmp
tar --owner=root --group=root -czvf ../hm_pdetect-$(cat ../../VERSION).tar.gz *
cd ..
rm -rf tmp
