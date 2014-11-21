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


// prototypes
void () W_WeaponFrame;
void() W_SetCurrentAmmo;
void() player_pain;
void() player_stand1;
void() Player_Jump;

void Impulse_MoveTurn(float imp);


/* TEST CRUD

	entity lock = find(world, classname, "test_lock");
	if (lock && !lock.deadflag)
	{
		lock.deadflag = DEAD_DEAD;

		activator = self;

		self = lock;
		SUB_UseTargets();
	}
*/


void Player_QueueImpulse(entity pl, float imp)
{
	if (pl.saved_impulse & 0xF0000)
		return;	// no more room

	if (pl.saved_impulse & 0xF000)
		imp = imp * 65536;
	else if (pl.saved_impulse & 0xF00)
		imp = imp * 4096;
	else if (pl.saved_impulse & 0xF0)
		imp = imp * 256;
	else if (pl.saved_impulse & 0xF)
		imp = imp * 16;

	pl.saved_impulse = pl.saved_impulse | imp;
}


float Player_UnqueueImpulse(entity pl)
{
	float imp = pl.saved_impulse & 0xF;

	pl.saved_impulse = floor(pl.saved_impulse / 16) & 0xFFFF;

	return imp;
}


void Player_MoveTurn(entity pl)
{
	float howlong = time - self.last_move_time;
	self.last_move_time = time;

	if (howlong <= 0) return;
	if (howlong > 0.1) howlong = 0.1;


	/* movement */

	if (self.dest != '0 0 0')
	{
		float MOVE = 500 * howlong;

		vector diff = self.dest - self.origin;

		diff_z = 0;

		if (vlen(diff) < MOVE)
		{
			// we have arrived
			self.origin = self.dest;
			self.dest   = '0 0 0';

			if (pl.saved_impulse)
			{
				Impulse_MoveTurn(Player_UnqueueImpulse(pl));
			}
		}
		else
		{
			diff = normalize(diff) * MOVE;

			self.origin = self.origin + diff;
		}

		setorigin(self, self.origin);
	}


	/* turning */

	if (self.dest2_x)
	{
		float MOVE = 250.0 * howlong;

		float diff = angle_diff(self.angles_y, self.dest2_y);

print(sprintf("Player_Turn : MOVE=%1.2f  diff=%1.2f  cur_yaw:%1.2f\n",
MOVE, diff, self.angles_y));

		if (fabs(diff) < MOVE)
		{
print("  ARRIVED\n");
			// we have arrived
			self.angles_y = self.dest2_y;
			self.dest2    = '0 0 0';

			if (pl.saved_impulse)
			{
				Impulse_MoveTurn(Player_UnqueueImpulse(pl));
			}
		}
		else
		{
			if (diff < 0)
				MOVE = -MOVE;

			self.angles_y = self.angles_y + MOVE;
print(sprintf("  added %1.2f ---> %1.2f\n", MOVE, self.angles_y));
		}

		self.fixangle = true;
	}
}


void Impulse_Movement(float imp)
{
	float pl_dir = Dir_FromAngle(self.angles_y);

	float dir = imp;

	vector new_tile = Tile_Neighbor(self.tile_pos, dir);
	vector new_pos  = Tile_MiddleCoord(new_tile);

	new_pos_z = 0;

	// !!! FIXME : CHECK IF MOVE IS VALID !!!

	// update 'tile_pos' immediately, but origin will shift over time

	self.tile_pos = new_tile;

	self.dest = new_pos;
}


void Impulse_Turning(float imp)
{
	float delta;

	if (imp == 5)
		delta = -90;
	else if (imp == 6)
		delta = 90;
	else
		return;

	// if already turning, just update existing target

	if (! self.dest2_x)
	{
		self.dest2_x = 1;
		self.dest2_y = self.angles_y;
	}

	self.dest2_y = sane_angle(self.dest2_y + delta);
}


void Impulse_MoveTurn(float imp)
{
	if (imp < 5)
		Impulse_Movement(imp);
	else
		Impulse_Turning(imp);
}


void ImpulseCommands()
{
	if (self.impulse <= 0)
		return;

print(sprintf("impulse %d\n", self.impulse));

	// ignore non-movement impulses while moving

	if (! (self.dest == '0 0 0' && ! self.dest2_x))
	{
		// queue up movements for later
		// [ but they still get clobbered by non-movement impulses ]
		if (self.impulse < 10)
		{
			Player_QueueImpulse(self, self.impulse);
			self.impulse = 0;
		}
		else
		{
			// otherwise leave 'impulse' as-is
			// [ it will get executed later unless clobbered by a new one ]
		}

		return;
	}


	if (self.impulse < 10)
	{
		Impulse_MoveTurn(self.impulse);
	}
	else
	{
		// TODO other commands

		// forget saved movement commands too
		self.saved_impulse = 0;
	}

	self.impulse = 0;
}


//----------------------------------------------------------------------

// andrewj: this is called just before the server is killed, and needs to
//          store persistent stats into the 'parmXX' globals.
void() SetChangeParms =
{
	if (self.health <= 0)
	{
		SetNewParms ();
		return;
	}

// remove items
	self.items = self.items - (self.items & 
	(IT_KEY1 | IT_KEY2 | IT_INVISIBILITY | IT_INVULNERABILITY | IT_SUIT | IT_QUAD) );
	
// cap super health
	if (self.health > 100)
		self.health = 100;
	if (self.health < 50)
		self.health = 50;
	if (self.ammo_shells < 25)
		self.ammo_shells = 25;

	INV_EncodeSpawnParms(self);
};


// andrewj: this is called _once_per_game_ when a client first connects to
//          the server.  It must set the initial state in 'parmXX' globals.
//          NOTE: it never touches the 'self' entity (it is null here).
void() SetNewParms =
{
	INV_InitialSpawnParms();
};


void() set_suicide_frame;

// called by ClientKill and DeadThink
void() respawn =
{
	if (coop)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// get the spawn parms as they were at level start
		setspawnparms (self);
		// respawn		
		PutClientInServer ();
	}
	else if (deathmatch)
	{
		// make a copy of the dead body for appearances sake
		CopyToBodyQue (self);
		// set default spawn parms
		SetNewParms ();
		// respawn		
		PutClientInServer ();
	}
	else
	{	// restart the entire server
		localcmd ("restart\n");
	}
};


/*
============
ClientKill

Player entered the suicide command
============
*/
void() ClientKill =
{
	bprint (self.netname);
	bprint (" suicides\n");
	set_suicide_frame ();
	self.frags = self.frags - 2;	// extra penalty
	respawn ();
};

float(vector v) CheckSpawnPoint =
{
	return FALSE;
};

/*
============
SelectSpawnPoint

Returns the entity to spawn at
============
*/
entity() SelectSpawnPoint =
{
	entity spot;
	entity thing;
	float  pcount;

// choose a info_player_deathmatch point
	if (coop)
	{
		lastspawn = find(lastspawn, classname, "info_player_coop");
		if (lastspawn == world)
			lastspawn = find (lastspawn, classname, "info_player_start");
		if (lastspawn != world)
			return lastspawn;
	}
	else if (deathmatch)
	{
		spot = lastspawn;
		while (1)
		{
			spot = find(spot, classname, "info_player_deathmatch");
			if (spot != world)
			{
				if (spot == lastspawn)
					return lastspawn;
				pcount = 0;
				thing = findradius(spot.origin, 32);
				while(thing)
				{
					if (thing.classname == "player")
						pcount = pcount + 1;
					thing = thing.chain;
				}
				if (pcount == 0)
				{
					lastspawn = spot;
					return spot;
				}
			}
		}
	}

	if (serverflags)
	{	// return with a rune to start
		spot = find (world, classname, "info_player_start2");
		if (spot)
			return spot;
	}
	
	spot = find (world, classname, "info_player_start");
	if (!spot)
		error ("PutClientInServer: no info_player_start on level");
	
	return spot;
};


entity MakeDropIndicator(entity pl)
{
	entity e = spawn();

	setmodel(e, "models/drop_spot.obj");

	e.skin = 0;
	e.scale = 1;

	e.alpha = 0.25;
	e.solid = SOLID_NOT;
	e.effects = EF_NODRAW;

	setsize (e, '-16 -16 0', '16 16 56');

//	e.angles = '90 0 0';
	e.view_ofs = '0 0 2';

	// only shown to this player
	e.drawonlytoclient = pl;

	return e;
}


// andrewj: this is called by the server for each new map.
//          [ some game code also calls it when respawning ]
//          the only persistent data from last map are in 'parmXX' globals
//          (which need to be decoded here, even for very first map).
void PutClientInServer()
{
	entity spot;

	spot = SelectSpawnPoint();

	self.classname = "player";
	self.health = 100;
	self.armorvalue = 50;
	self.takedamage = DAMAGE_AIM;

	// andrewj: no physics with TMX pieces yet -- use no-clip mode
	self.solid = SOLID_NOT;
	self.movetype = MOVETYPE_NONE;	// i.e. DIY

	self.show_hostile = 0;
	self.max_health = 100;
	self.flags = FL_CLIENT;
	self.air_finished = time + 12;
	self.dmg = 2;   		// initial water damage
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.invisible_finished = 0;
	self.invincible_finished = 0;
	self.effects = 0;
	self.invincible_time = 0;

	INV_DecodeSpawnParms(self);
	INV_SendAllToClient(self);
	
	W_SetCurrentAmmo ();

	self.attack_finished = time;
//???	self.th_pain = player_pain;
//???	self.th_die = Player_Die;
	
	self.deadflag = DEAD_NO;
// paustime is set by teleporters to keep the player from moving a while
	self.pausetime = 0;
	
//	spot = SelectSpawnPoint ();

	self.origin = spot.origin + '0 0 1';
	self.tile_pos = spot.tile_pos;
	self.angles = spot.angles;
	self.fixangle = TRUE;		// turn this way immediately

	setmodel (self, "progs/player.mdl");

	setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
	
	self.view_ofs = '0 0 40';

	player_stand1 ();
	
	if (deathmatch || coop)
	{
		makevectors(self.angles);
	}

	if (! self.drop_indicator)
		self.drop_indicator = MakeDropIndicator(self);
}



//----------------------------------------------------------------------

void() PlayerDeathThink =
{
	local float		forward;

	if ((self.flags & FL_ONGROUND))
	{
		forward = vlen (self.velocity);
		forward = forward - 20;
		if (forward <= 0)
			self.velocity = '0 0 0';
		else	
			self.velocity = forward * normalize(self.velocity);
	}

// wait for all buttons released
	if (self.deadflag == DEAD_DEAD)
	{
		if (self.button2 || self.button1 || self.button0)
			return;
		self.deadflag = DEAD_RESPAWNABLE;
		return;
	}

// wait for any button down
	if (!self.button2 && !self.button1 && !self.button0)
		return;

	self.button0 = 0;
	self.button1 = 0;
	self.button2 = 0;

	respawn();
};


/*
================
PlayerPreThink

Called every frame before physics are run
================
*/
void() PlayerPreThink =
{
	if (intermission_running)
	{
		IntermissionThink ();	// otherwise a button could be missed between
		return;					// the think tics
	}

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	makevectors (self.v_angle);		// is this still used

	CheckRules ();

	if (self.deadflag >= DEAD_DEAD)
	{
		PlayerDeathThink ();
		return;
	}
	
	if (self.deadflag == DEAD_DYING)
		return;	// dying, so do nothing

	Player_MoveTurn(self);

	if (self.button2)
	{
		Player_Jump();
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;

// teleporters can force a non-moving pause time	
	if (time < self.pausetime)
		self.velocity = '0 0 0';

	if(time > self.attack_finished && self.currentammo == 0 && self.weapon != IT_AXE)
	{
		self.weapon = W_BestWeapon ();
		W_SetCurrentAmmo ();
	}
};
	
/*
================
CheckPowerups

Check for turning off powerups
================
*/
void() CheckPowerups =
{
	if (self.health <= 0)
		return;

// invisibility
	if (self.invisible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invisible_sound < time)
		{
			sound (self, CHAN_AUTO, "items/inv3.wav", 0.5, ATTN_IDLE);
			self.invisible_sound = time + ((random() * 3) + 1);
		}


		if (self.invisible_finished < time + 3)
		{
			if (self.invisible_time == 1)
			{
				sprint (self, "Ring of Shadows magic is fading\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/inv2.wav", 1, ATTN_NORM);
				self.invisible_time = time + 1;
			}
			
			if (self.invisible_time < time)
			{
				self.invisible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.invisible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVISIBILITY;
			self.invisible_finished = 0;
			self.invisible_time = 0;
		}
		
	// use the eyes
		self.frame = 0;
	}

// invincibility
	if (self.invincible_finished)
	{
// sound and screen flash when items starts to run out
		if (self.invincible_finished < time + 3)
		{
			if (self.invincible_time == 1)
			{
				sprint (self, "Protection is almost burned out\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/protect2.wav", 1, ATTN_NORM);
				self.invincible_time = time + 1;
			}
			
			if (self.invincible_time < time)
			{
				self.invincible_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}
		
		if (self.invincible_finished < time)
		{	// just stopped
			self.items = self.items - IT_INVULNERABILITY;
			self.invincible_time = 0;
			self.invincible_finished = 0;
		}
		if (self.invincible_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}

// super damage
	if (self.super_damage_finished)
	{

// sound and screen flash when items starts to run out

		if (self.super_damage_finished < time + 3)
		{
			if (self.super_time == 1)
			{
				sprint (self, "Quad Damage is wearing off\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/damage2.wav", 1, ATTN_NORM);
				self.super_time = time + 1;
			}	  
			
			if (self.super_time < time)
			{
				self.super_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.super_damage_finished < time)
		{	// just stopped
			self.items = self.items - IT_QUAD;
			self.super_damage_finished = 0;
			self.super_time = 0;
		}
		if (self.super_damage_finished > time)
			self.effects = self.effects | EF_DIMLIGHT;
		else
			self.effects = self.effects - (self.effects & EF_DIMLIGHT);
	}	

// suit	
	if (self.radsuit_finished)
	{
		self.air_finished = time + 12;		// don't drown

// sound and screen flash when items starts to run out
		if (self.radsuit_finished < time + 3)
		{
			if (self.rad_time == 1)
			{
				sprint (self, "Air supply in Biosuit expiring\n");
				stuffcmd (self, "bf\n");
				sound (self, CHAN_AUTO, "items/suit2.wav", 1, ATTN_NORM);
				self.rad_time = time + 1;
			}
			
			if (self.rad_time < time)
			{
				self.rad_time = time + 1;
				stuffcmd (self, "bf\n");
			}
		}

		if (self.radsuit_finished < time)
		{	// just stopped
			self.items = self.items - IT_SUIT;
			self.rad_time = 0;
			self.radsuit_finished = 0;
		}
	}	

};


/*
================
PlayerPostThink

Called every frame after physics are run
================
*/
void() PlayerPostThink =
{
	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale

	if (self.deadflag)
		return;

	ImpulseCommands();

	INV_ObjectInteraction(self);

// check to see if player landed and play landing sound	
	if ((self.jump_flag < -300) && (self.flags & FL_ONGROUND) && (self.health > 0))
	{
		if (self.watertype == CONTENT_WATER)
			sound (self, CHAN_BODY, "player/h2ojump.wav", 1, ATTN_NORM);
		else if (self.jump_flag < -650)
		{
			T_Damage (self, world, world, 5); 
			sound (self, CHAN_VOICE, "player/land2.wav", 1, ATTN_NORM);
			self.deathtype = "falling";
		}
		else
			sound (self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);

		self.jump_flag = 0;
	}

	if (!(self.flags & FL_ONGROUND))
		self.jump_flag = self.velocity_z;

	CheckPowerups ();
};


/*
===========
ClientConnect

called when a player connects to a server

andrewj: called just before PutClientInServer() -- not sure if there
         are any circumstances when one is called without the other.
============
*/
void() ClientConnect =
{
	bprint (self.netname);
	bprint (" entered the game\n");
	
// a client connecting during an intermission can cause problems
	if (intermission_running)
		ExitIntermission ();
};


/*
===========
ClientDisconnect

called when a player disconnects from a server
============
*/
void() ClientDisconnect =
{
	if (gameover)
		return;
	// if the level end trigger has been activated, just return
	// since they aren't *really* leaving

	// let everyone else know
	bprint (self.netname);
	bprint (" left the game with ");
	bprint (ftos(self.frags));
	bprint (" frags\n");

///	sound (self, CHAN_BODY, "player/tornoff2.wav", 1, ATTN_NONE);

	set_suicide_frame ();
};


void(string s) SV_ParseClientCommand =
{
	// 'self' is the client which sent the command

	argc = tokenize(s);

	if (argv(0) == "invent_hl")
	{
		CMD_invent_hl(self);
	}
	else
	{
		clientcommand(self, s);
	}
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
