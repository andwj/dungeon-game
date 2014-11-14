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
	pointparticles(self.misc1, self.pos1, '0 0 0', 1);

	self.nextthink = time + 0.1;
}


void spawnfunc_torch()
{
	precache_model("models/torch_wall.obj");

	setmodel(self, "models/torch_wall.obj");
	self.skin = 0;
	self.scale = 0.5;

	// dummy bbox
	setsize(self, '-16 -16 0', '16 16 32');


	// start fire particles

	self.misc1 = particleeffectnum("AJ_TORCH");

	self.nextthink = time + 0.1;
	self.think = torch_burn;

	// adjust since our torch faces south (not east)
	makevectors(self.angles + '0 90 0');

	self.pos1 = self.origin + 10 * v_forward + '0 0 22';
}


void spawnfunc_table()
{
	precache_model("models/table.obj");

	setmodel(self, "models/table.obj");

	self.skin = 0;
	self.scale = 1.0;
	self.solid = SOLID_BBOX;

	setsize(self, '-76 -16 0', '76 16 40');
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
