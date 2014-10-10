#!/bin/bash
set -e

dest=oga-game-XXX

echo "Packing everything to.... " $dest

mkdir $dest

# Binaries
# (no actual EXEs.... yet)
mkdir -v $dest/bin

cp -v Run.bat $dest
cp -v Run-linux.sh $dest
chmod 755 $dest/Run-linux.sh

# Data
cp -av oga $dest/oga

# Source code
mkdir -v $dest/source

cp -av game   $dest/source/game
cp -av client $dest/source/client
cp -av menu   $dest/source/menu

rm -fv $dest/*/fteqcc.log

#  Documentation
#TODO

# OK done
#
echo "------------------------------------"
echo "zip -l -r oga-game-XXX oga-game-XXX.zip"
echo ""
