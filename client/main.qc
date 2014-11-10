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


float free_camera;

void SetCameraMode(float enable)
{
	if (free_camera == enable)
		return;

	free_camera = enable;

	if (enable)
	{
		setcursormode(0);
		cvar_set("cl_prydoncursor", "0");
	}
	else
	{
		cvar_set("cl_prydoncursor", "1");
		setcursormode(1);

		// FIXME RESET ANGLE ?
	}
}


void CMD_cameramode()
{
	if (argv(1) == "1")
		SetCameraMode(TRUE);
	else
		SetCameraMode(FALSE);
}


void CMD_togglecamera()
{
	SetCameraMode(! free_camera);
}


void UI_DrawFreeLook()
{
	if (! free_camera)
		return;
	
	vector pic_size = drawgetimagesize("gfx/freelook");

	vector pos = '0 25 0';

	pos_x = (scr_width - pic_size_x) / 2;

	drawpic(pos, "gfx/freelook", SIZE_NORMAL, COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
}


void UI_DrawFrameAroundView(float tile_w, float tile_h, float frame_y, float pass)
{
	// pass == 0 before rendering the view, 1 afterwards

	// on second pass just fix up some bits
	if (pass > 0)
	{
		drawsubpic(to_vector(0, frame_y, 0), '12 10 0', "gfx/borders",
		           '0 0 0', '12 10 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
		return;
	}

	// corners

	drawsubpic(to_vector(0, frame_y, 0), '32 32 0', "gfx/borders",
			   '0 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	drawsubpic(to_vector((tile_w - 1) * 32, frame_y, 0), '32 32 0', "gfx/borders",
			   '64 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	drawsubpic(to_vector(0, frame_y + (tile_h - 1) * 32, 0), '32 32 0', "gfx/borders",
			   '0 64 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	drawsubpic(to_vector((tile_w - 1) * 32, frame_y + (tile_h - 1) * 32, 0), '32 32 0', "gfx/borders",
			   '0.5 0.5 0', '0.5 0.5 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

	// sides

	float x, y;

	for (x = 1 ; x < tile_w - 1 ; ++x)
	{
		drawsubpic(to_vector(x * 32, frame_y, 0), '32 32 0', "gfx/borders",
				   '32 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

		drawsubpic(to_vector(x * 32, frame_y + (tile_h - 1) * 32, 0), '32 32 0', "gfx/borders",
				   '32 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
	}

	for (y = 1 ; y < tile_h - 1 ; ++y)
	{
		drawsubpic(to_vector(0, frame_y + y * 32, 0), '32 32 0', "gfx/borders",
				   '32 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);

		drawsubpic(to_vector((tile_w - 1) * 32, frame_y + y * 32, 0), '32 32 0', "gfx/borders",
				   '32 0 0', '32 32 0', COLOR_NORMAL, ALPHA_NORMAL, DRAWFLAG_NORMAL);
	}
}


void UI_RenderWorld()
{
	float tile_w = floor(scr_width  / 32) - 4;
	float tile_h = floor(scr_height / 32);

	float frame_y = floor((scr_height - tile_h * 32) / 2);

	UI_DrawFrameAroundView(tile_w, tile_h, frame_y, 0);


	clearscene();

setproperty(VF_SIZE_X, scr_width - 120);

	setproperty(VF_DRAWWORLD, 1);

	addentities(MASK_ENGINE | 0 /* MASK_ENGINEVIEWMODELS */ | MASK_NORMAL);

//!!!!	renderscene();

setproperty(VF_SIZE_X, scr_width);


	UI_DrawFrameAroundView(tile_w, tile_h, frame_y, 1);
}


// ------------------------------------------------------------------------


void CSQC_Init()
{
	print("UI Init....\n");

	INV_Create();

	registercommand("ui_highlight");
	registercommand("ui_invent");
	registercommand("ui_drag");
	registercommand("ui_can_drop");

	// stuff for key bindings
	registercommand("cameramode");
	registercommand("togglecamera");

	// turn on Prydon cursor mode
	cvar_set("cl_prydoncursor", "1");

	// ensure we get mouse move events (even with Prydon cursor enabled)
	// [ getmousepos() does not work without this ]
  	setcursormode(1);
}


void CSQC_Shutdown()
{
	print("UI Shutdown....\n");
}


float CSQC_ConsoleCommand(string cmd)
{
	argc = tokenize(cmd);

	if (argv(0) == "ui_highlight")
	{
		CMD_highlight();
	}
	else if (argv(0) == "ui_invent")
	{
		CMD_invent();
	}
	else if (argv(0) == "ui_drag")
	{
		CMD_drag();
	}
	else if (argv(0) == "ui_can_drop")
	{
		CMD_can_drop();
	}
	else if (argv(0) == "cameramode")
	{
		CMD_cameramode();
	}
	else if (argv(0) == "togglecamera")
	{
		CMD_togglecamera();
	}
	else
	{
		// oops, unknown command
		// [ should not happen, we only get registered commands ]
		return 0;
	}

	// known command
	return 1;
}


void CSQC_UpdateView(float vwidth, float vheight)
{
	UpdateScreenSize();

	mouse_pos = getmousepos();

	UI_CheckMouseOverGUI();

	UI_RenderWorld();

	UI_DrawFreeLook();
//	UI_Draw();
}


#define EVENT_KeyDown    0
#define EVENT_KeyUp      1
#define EVENT_RelMouse   2
#define EVENT_AbsMouse   3


float CSQC_InputEvent(float evtype, float x, float y)
{
	// TODO

	return 0;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
