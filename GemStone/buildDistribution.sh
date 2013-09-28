#!/bin/sh

#  buildDistribution.sh
#  GemStone
#
#  Created by James Foster on 10/12/12.
#  Copyright (c) 2012-2013 GemTalk Systems LLC. All rights reserved.

set -x

cd $TARGET_BUILD_DIR/
rm GemStoneApp.dmg GemStoneApp.sparseimage /Users/$USER/Desktop/GemStoneApp.dmg 2> /dev/null

if [[ $1 = "clean" ]] ; then
echo "clean does not require any further activity"
exit 0
fi

echo "** Copy disk image template"
hdiutil convert $PROJECT_DIR/GemStoneApp.dmg -format UDSP -o ./GemStoneApp.sparseimage
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
cd $TARGET_BUILD_DIR/GemStone.app/
echo "** Copy files to disk image"
cp -PR * /Volumes/GemStoneApp/GemStone.app/
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
cd ../
hdiutil detach /Volumes/GemStoneApp/
echo "** Convert disk image"
hdiutil convert GemStoneApp.sparseimage -format UDBZ -o GemStoneApp.dmg
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
mv GemStoneApp.dmg /Users/$USER/Desktop/GemStoneApp.dmg
rc=$?
if [[ $rc != 0 ]] ; then
exit $rc
fi
echo "** Moving disk image to Desktop"
rm ./GemStoneApp.sparseimage