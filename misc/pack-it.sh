#!/bin/bash
set -e

dest=oga-game-XXX

mkdir $dest

# Binaries
# (no actual EXEs.... yet)
mkdir $dest/bin

# Data
cp -a oga $dest/oga

# Source code
mkdir $dest/source

cp -a game   $dest/source/game
cp -a client $dest/source/client
cp -a menu   $dest/source/menu

#  Documentation
#TODO

# OK done
#
echo "------------------------------------"
echo "zip -l -r oga-game-XXX oga-game-XXX.zip"
echo ""
