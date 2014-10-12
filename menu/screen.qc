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

#define SIZE_NORMAL  '0 0 0'

// copies of the cvars with the same names
// (not just for convenience, also to detect when those cvars have changed)
float vid_width;
float vid_height;
float vid_pixelheight;

// virtual size of screen
// (sent to vid_conwidth and vid_conheight cvars)
float scr_width;
float scr_height;

vector scr_size;

// current position of mouse pointer (x=0..scr_width, y=0..scr_height)
vector mouse_pos;


// check if video resolution has changed, update our virtual size
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
		return 0;  // no change
	}

	vid_width  = w;
	vid_height = h;
	vid_pixelheight = p;

	// compute new size of virtual screen
	// requirements:
	//    1. height is the main factor
	//    2. if real size < 4:3 aspect, squish, otherwise keep same aspect ratio
	//    3. vid_pixelheight changes final width (i.e. we squish or stretch horizontally
	//       to account for non-square pixels)

	scr_height = 768;

	scr_width = scr_height * w / h;

	// adjust for non-square pixels
	scr_width = scr_width / p;

	// leave enough horizontal room for UI stuff
	if (scr_width < scr_height * 1.25)
		scr_width = scr_height * 1.25;

	scr_size = '0 0 0';
	scr_size_x = scr_width;
	scr_size_y = scr_height;

	cvar_set("vid_conwidth",  ftos(scr_width));
	cvar_set("vid_conheight", ftos(scr_height));

	mouse_pos = getmousepos();

	return 1;
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
