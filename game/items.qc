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


void spawnfunc_key()
{
	precache_model ("models/key1.obj");

	setmodel (self, "models/key1.obj");
	self.skin = 0;
	self.scale = 1;
	setsize (self, '-16 -16 0', '16 16 36');

	self.description = "a rusty old key";
	self.icon_pic = "models/key1_icon";

	self.item_kind = ITEM_KEY;
	self.i_keys = 1;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
