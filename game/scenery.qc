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


void torch()
{
	precache_model ("models/torch_wall.obj");

	setmodel (self, "models/torch_wall.obj");
	self.skin = 0;
	self.scale = 3;

	// dummy
	setsize (self, '-16 -16 0', '16 16 32');

	// TODO : spawn a light
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
