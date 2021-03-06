dungeon-game
============

Welcome!

This is a snapshot for the OGA (OpenGameArt.org) community dungeon game
project.  This project has only just begun, so there is not much to see
yet.

IMPORTANT NOTE: all assets in the 'yd' folder are licensed to
use in this OGA Dungeon-related project _ONLY_.
These resources are **NOT FREE** to use,
they are NOT under Creative Commons of any sort.
Exclusive permission is granted to use them *ONLY* in
this OGA Dungeon-related Project.

##Running under Windows

Windows users can double-click the '`Run`' script.

##Running under Linux

Linux users can use the '`Run-linux.sh`' script.  This script can detect a
Darkplaces which has been installed on the system (e.g. from the 'darkplaces'
package), but note that versions older than 2013 probably will not work
properly (that includes the package in Debian Wheezy).

You may need to compile the Darkplaces engine yourself.  Make sure that
your compiled version includes the necessary libraries, for example in
the 'makefile' file search for the following comment and add the extra
lines after it:

    ##### Extra CFLAGS #####
    LINK_TO_ZLIB=1
    LINK_TO_PNG=1
    LINK_TO_LIBJPEG=1
    LINK_TO_FREETYPE2=1

Rename the executable from (e.g.) darkplaces-sdl --> darkplaces-custom,
and copy it into the '`bin`' directory, and the '`Run-linux.sh`' script
will find it there.

