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


/*
 * This file contains utilities which are common to all three
 * programs (MENU, CLIENT, GAME).
 */


//
// Use this to keep around strings which may be tempstrings, such as
// from tokensize() + argv().  For a global var or field, decided whether
// it needs to be zoned and then ALWAYS use this to set the value, like:
//
//    myglobalstr = zoned_string(myglobalstr, new_value);
//
// Be aware of code which stores your 'myglobalstr' value somewhere and
// then calls a function which may change it -- the strzone() here will
// invalidate the previous value (leading to weird behavior or a crash).
// If that situation arises, use the zoned_to_temp() function below, or
// store it in another zoned string variable.
//
string zoned_string(string old_s, string new_s)
{
	if (old_s != "")
		strunzone(old_s);

	if (new_s == "")
		return "";

	return strzone(new_s);
}

string zoned_to_temp(string cur_s)
{
	// luckily Darkplaces (2013-03-04 version) does not optimize strcat()
	// by checking for empty strings.  So we always get a tempstring.

	return strcat(cur_s, "");
}


//
// create a vector from components
//
vector to_vector(float x, float y, float z)
{
	vector vec;

	vec_x = x;
	vec_y = y;
	vec_z = z;

	return vec;
}


//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
