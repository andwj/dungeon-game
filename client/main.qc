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


void CSQC_Init()
{
	print("UI Init....\n");

//  UI_InitStats();
	UI_CreateInventory();

	registercommand("ui_describe");

	// turn on Prydon cursor mode
	cvar_set("cl_prydoncursor", "1");

	// ensure we get mouse move events (even with Prydon cursor enabled)
	setcursormode(1);
}


void CSQC_Shutdown()
{
	print("UI Shutdown....\n");
}


float CSQC_ConsoleCommand(string cmd)
{
	tokenize(cmd);

	if (argv(0) == "ui_describe")
	{
		UI_CMD_describe(cmd);
		return 1;
	}

	return 0;
}


void CSQC_UpdateView(float vwidth, float vheight)
{
	UpdateScreenSize();

	mouse_pos = getmousepos();

	UI_RenderWorld();

	UI_Draw();
}


#define EVENT_KeyDown    0
#define EVENT_KeyUp      1
#define EVENT_RelMouse   2
#define EVENT_AbsMouse   3


float CSQC_InputEvent(float evtype, float x, float y)
{
	return 0;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
