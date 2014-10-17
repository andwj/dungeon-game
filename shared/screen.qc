//========================================================================
//
//  Copyright (C) 2014  Andrew Apted
//
//  This code is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published
//  by the Free Software Foundation; either version 2 of the License,
//  or (at your option) any later version.
//
//========================================================================

//
// NOTE: this code is shared between MENU and CLIENT VMs.
//       hence it should stay as self-contained as possible.
//

#define  SIZE_NORMAL	'0 0 0'
#define COLOR_NORMAL	'1 1 1'
#define ALPHA_NORMAL	1.0


/* ---- SCREEN SCALING / ASPECT STUFF --- */

//
// The main principle is to keep the screen 1:1 pixels (no scaling)
// when the screen is in a certain range, and to scale up when it is
// above the range, scale down when it is below it (too small).
//
// [ that assumes the pixel aspect ratio is equal or close to 1:1 ]
//
// The primary criterion to scale or not is based on the HEIGHT of the
// screen (or window) -- i.e. vid_height.  When it is < MIN_VID_HEIGHT,
// then we scale down.  When >= (2 * MIN_VID_HEIGHT) then we scale up by
// a whole number (2, 3 or 4) to prevent blurring pixels.
//
// [ there will be an option to never scale up, and an option to
//   always scale down (make everything as large as possible) ]
//
// Horizontally, we also need to ensure there is enough space for UI
// elements.  We impose a minimum aspect ratio of 5:4.  If the final
// aspect would be < this, then we squish the screen horizontally.
//
// Final width is adjusted for the pixel aspect ratio (vid_pixelheight),
// unless it is close to 1:1 then we do not apply it.
//
// [ there will be an option to always honor the pixel aspect ]
//

#define MIN_VID_HEIGHT	600
#define MIN_VID_ASPECT	(5 / 4)


// copies of the cvars with the same names
// (not just for convenience, also to detect when those cvars have changed)
float vid_width;
float vid_height;
float vid_pixelheight;
float vid_options;

// virtual size of screen
// (sent to vid_conwidth and vid_conheight cvars)
float scr_width;
float scr_height;

vector scr_size;

// set this to 1 to force update of screen (after RESET ALL SETTINGS)
// the update will happen a few frames later.
float scr_force_update;

// current position of mouse pointer (x=0..scr_width, y=0..scr_height)
vector mouse_pos;


//
// Check if video resolution has changed, update our virtual size.
// Returns TRUE if screen did change size.
//
bool UpdateScreenSize()
{
	float w = cvar("vid_width");
	float h = cvar("vid_height");
	float p = cvar("vid_pixelheight");
	float o = cvar("vid_options");

	// sanity check
	if (w < 16) w = 16;
	if (h < 10) h = 10;

	if (p < 0.25) p = 0.25;
	if (p > 4.00) p = 4.00;

	if (scr_force_update > 0)
		scr_force_update = scr_force_update + 1;

	if ((scr_force_update < 3) &&
		w == vid_width &&
		h == vid_height &&
		p == vid_pixelheight &&
		o == vid_options)
	{
		return false;  // no change
	}

	vid_width  = w;
	vid_height = h;
	vid_pixelheight = p;
	vid_options = o;

	scr_force_update = 0;


	// --- compute new size of virtual screen ---

	scr_height = vid_height;
	
	// need to scale down?
	if (scr_height < MIN_VID_HEIGHT)
		scr_height = MIN_VID_HEIGHT;

	if (o & 1)
	{
		// no scaling up
	}
	else if (o & 2)
	{
		// maximum scaling up
		scr_height = MIN_VID_HEIGHT;
	}
	else if (o & 4)
	{
		scr_height = MIN_VID_HEIGHT * 2;
	}
	else
	{
		// need to scale up?  use a whole number of pixels (no blurring)
		if (scr_height > 4 * MIN_VID_HEIGHT)
			scr_height = floor(scr_height / 4);
		else if (scr_height > 3 * MIN_VID_HEIGHT)
			scr_height = floor(scr_height / 3);
		else if (scr_height > 2 * MIN_VID_HEIGHT)
			scr_height = floor(scr_height / 2);
	}

	scr_width = scr_height * w / h;

	// adjust for non-square pixels
	if (! (o & 8))
		scr_width = scr_width / p;

	// leave enough horizontal room for UI stuff
	if (scr_width < scr_height * MIN_VID_ASPECT)
		scr_width = scr_height * MIN_VID_ASPECT;


	scr_size = '0 0 0';
	scr_size_x = scr_width;
	scr_size_y = scr_height;

	cvar_set("vid_conwidth",  ftos(scr_width));
	cvar_set("vid_conheight", ftos(scr_height));

	mouse_pos = getmousepos();

	return true;
}


//
// Draws the picture so it covers most of the screen.
//
// It will be scaled so that it vertically filled the screen, and then
// centered horizontally.  If it does not fit horizontally, the gaps at
// left/right edges are filled with 'gap_color'.
//
// Recommended size of image is 1280x768.
//
void SCR_DrawBackground(string pic_name, vector gap_color)
{
	vector pic_size;

	pic_size = drawgetimagesize(pic_name);


	vector new_size;

	new_size_y = scr_height;
	new_size_x = scr_height * (pic_size_x / pic_size_y);
	new_size_z = 0;

	if (new_size_x < scr_width)
	{
		// hmmm, optimise this?
		drawfill('0 0 0', scr_size, gap_color, 1.0, DRAWFLAG_NORMAL);
	}


	vector new_pos = '0 0 0';

	new_pos_x = (scr_width - new_size_x) / 2;

	drawpic(new_pos, pic_name, new_size, '1 1 1', 1.0, DRAWFLAG_NORMAL);
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
