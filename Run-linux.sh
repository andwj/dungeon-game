#/bin/sh
# if installed by a package manager, run that one
if type -t darkplaces ; then
  darkplaces -game oga ;
else
  bin/darkplaces-linux-686-sdl -game oga ;
fi
