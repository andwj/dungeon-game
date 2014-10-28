#/bin/sh

# if a custom-built one exists, run it
if [ -f bin/darkplaces-custom ] ; then
  bin/darkplaces-custom -customgamedirname1 oga -game yd ;
# or if installed from a package, run that one
elif type -t darkplaces ; then
  darkplaces -customgamedirname1 oga -game yd ;
else
  bin/darkplaces-linux-686-sdl -customgamedirname1 oga -game yd ;
fi
