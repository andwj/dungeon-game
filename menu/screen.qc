//
// NOTE: this code is shared between MENU and CLIENT VMs.
//       hence it should stay as self-contained as possible.
//

// copies of the cvars with the same names
// (not just for convenience, also used to detect when those cvars have changed)
float vid_width;
float vid_height;
float vid_pixelheight;

// virtual size of screen
// (sent to vid_conwidth and vid_conheight)
float scr_width;
float scr_height;

// current position of mouse pointer (x=0..scr_width, y=0..scr_height)
vector mouse_pos;


// check if screen changed size, and upda
// returns 1 if screen did change size, 0 normally
float UpdateScreenSize()
{
	float w = cvar("vid_width");
	float h = cvar("vid_height");
	float p = cvar("vid_pixelheight");

	// sanity check
	if (w < 16) w = 16;
	if (h < 10) h = 10;

	if (p < 0.25) p = 0.25;
	if (p > 4.00) p = 4.00;

	if (w == vid_width &&
		h == vid_height &&
		p == vid_pixelheight)
	{
		return 0;
	}

	// compute new size of virtual screen
	// requirements:
	//    1. height is main thing we check
	//    2. if real size < 4:3 aspect, allow squishing, otherwise keep same aspect ratio
	//    3. vid_pixelheight changes final width (i.e. we squish or stretch horizontally
	//       to account for non-square pixels)

	if (h < 392 ||
	    (h/2 > 376 && h/2 < 392) ||
	    (h/3 > 376 && h/3 < 392) ||
	    (h/4 > 376 && h/4 < 392))
	{
		scr_height = 384;
	}
	else
	{
		scr_height = 400;
	}

	float w2 = w;
	if (w / h < 1.5)
		w2 = w2 * (1.5 / (w / h));

	scr_width = scr_height * w2 / h / p;

	cvar_set("vid_conwidth",  ftos(scr_width));
	cvar_set("vid_conheight", ftos(scr_height));

	mouse_pos = getmousepos();
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
