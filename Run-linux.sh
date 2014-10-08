#/bin/sh
# if installed by a package manager, run that one
if type -t darkplaces ; then
  darkplaces -customgamedirname1 oga ;
else
  bin/darkplaces-linux-686-sdl -customgamedirname1 oga ;
fi
