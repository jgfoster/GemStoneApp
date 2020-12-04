#!/bin/sh

#  buildDistribution.sh
#  GemStone
#
#  Created by James Foster on 10/12/12.
#  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.

set -x

cd $TARGET_BUILD_DIR
pwd
ls -alF
rm GemStoneApp.dmg GemStoneApp.sparseimage $PROJECT_DIR/GemStoneApp.dmg 2> /dev/null && true

if [[ $1 == "clean" ]] ; then
echo "clean does not require any further activity"
exit 0
fi

echo "** Copy disk image template"
hdiutil convert $PROJECT_DIR/Empty.dmg -format UDSP -o ./GemStoneApp.sparseimage
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
echo "** Mount new disk image"
hdiutil attach ./GemStoneApp.sparseimage
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
pwd
cd GemStone.app
pwd
echo "** Copy files to disk image"
ls -alF
cp -PR * /Volumes/GemStoneApp/GemStone.app/
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
pwd
cd ../
pwd
cd $TARGET_BUILD_DIR
pwd
sleep 1
hdiutil detach /Volumes/GemStoneApp/
echo "** Convert disk image"
ls -alF
hdiutil convert GemStoneApp.sparseimage -format UDBZ -o GemStoneApp.dmg
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
mv GemStoneApp.dmg $PROJECT_DIR/GemStoneApp.dmg
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
echo "** Moving disk image to Project"
rm ./GemStoneApp.sparseimage
