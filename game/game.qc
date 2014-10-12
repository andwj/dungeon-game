//========================================================================
//
//  Copyright (C) 1996-1997  Id Software, Inc.
//  Copyright (C)      2014  Andrew Apted
//
//  This code is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published
//  by the Free Software Foundation; either version 2 of the License,
//  or (at your option) any later version.
//
//========================================================================

//
// This file contain game-state stuff, e.g. intermissions, victory,
// what happens when you die, etc....
//
// Also implements any non-client-related server callbacks.
//


void SV_Shutdown()
{
	/* nothing needed */
}


// andrewj: called by server at beginning of SV_Physics()
void StartFrame()
{
	teamplay = cvar("teamplay");
	skill = cvar("skill");
	framecount = framecount + 1;
}

// andrewj: called by server at end of SV_Physics()
void EndFrame()
{
	/* nothing needed */
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
