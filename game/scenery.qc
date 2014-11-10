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


void torch_burn()
{
	pointparticles(self.misc1, self.origin + '0 -10 22', '0 0 0', 1);

	self.nextthink = time + 0.1;
}


void torch()
{
	precache_model ("models/torch_wall.obj");

	setmodel (self, "models/torch_wall.obj");
	self.skin = 0;
	self.scale = 0.5;

	self.misc1 = particleeffectnum("AJ_TORCH");

	// dummy
	setsize (self, '-16 -16 0', '16 16 32');

	self.nextthink = time + 0.1;
	self.think = torch_burn;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
