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
echo "Copying game assets...."

cp -a oga $dest/oga

# Source code
mkdir -v $dest/source

echo "Copying QC source...."

cp -a game   $dest/source/game
cp -a client $dest/source/client
cp -a menu   $dest/source/menu
cp -a shared $dest/source/shared
cp -a dpdefs $dest/source/dpdefs
cp -a Makefile $dest/source/

#  Documentation
markdown --html4tags doc/README_pack.md > $dest/README.html
#TODO LICENSES

# OK done
#
echo "---------------------------------------"
echo "zip -l -r oga-game-XXX.zip oga-game-XXX"
echo ""
