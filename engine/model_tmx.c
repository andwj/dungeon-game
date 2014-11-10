/*
Copyright (C) 2014 Andrew Apted

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "image.h"
#include "r_shadow.h"
#include "polygon.h"
#include "curves.h"
#include "wad.h"


// bring in Expat XML parser header
#include <expat.h>


// TODO : make these properties of the TMX <map> element
#define TMX_TILE_SIZE	256.0
#define TMX_CEILING_H	(0.5 * TMX_TILE_SIZE)


#define MAX_TMX_ENT_STRING	1048576


typedef struct tmx_piece_s
{
	char model_name[64];

	struct model_s * model;

} tmx_piece_t;


typedef struct tmx_static_entity_s
{
	tmx_piece_t * piece;

	// TODO: keep these three fields?
	vec3_t origin;
	vec3_t angles;
	float scale;

	entity_render_t render;

	// link for list [ FIXME : won't be usable for multiple leafs! ]
	struct tmx_static_entity_s * next;
}
tmx_static_entity_t;



extern int Mod_Q1BSP_CreateShadowMesh(dp_model_t *mod);


static unsigned char nobsp_pvs[1] = {1};


static tmx_piece_t * TMX_AddPiece(dp_model_t *mod, const char *name)
{
	int i;

	for (i = 0 ; i < mod->tmx.num_pieces ; i++)
		if (strcmp(mod->tmx.pieces[i].model_name, name) == 0)
			return &mod->tmx.pieces[i];
	
	if (mod->tmx.num_pieces >= MAX_TMX_PIECES)
		Host_Error("Mod_TMX_Load : too many pieces (>= %d)\n", MAX_TMX_PIECES);

	int new_idx = mod->tmx.num_pieces;
	mod->tmx.num_pieces += 1;

	strlcpy(mod->tmx.pieces[new_idx].model_name, name, sizeof(mod->tmx.pieces[new_idx].model_name));

	// model is loaded later (by TMX_LoadPieces)
	mod->tmx.pieces[new_idx].model = NULL;

	return &mod->tmx.pieces[new_idx];
}


static void TMX_AddStaticEnt(dp_model_t *mod, const char *piece_model, vec3_t origin, vec3_t angles)
{
	tmx_static_entity_t * ent;

	ent = (tmx_static_entity_t *)Mem_Alloc(mod->mempool, sizeof(tmx_static_entity_t));

	ent->piece = TMX_AddPiece(mod, piece_model);

	VectorCopy(origin, ent->origin);
	VectorCopy(angles, ent->angles);

	ent->scale = TMX_TILE_SIZE;

	// link in
	ent->next = mod->tmx.ents;
	mod->tmx.ents = ent;
}


typedef enum tmx_container_type_e
{
	CONTAINER_NONE = 0,
	CONTAINER_Tileset,
	CONTAINER_Layer,
	CONTAINER_ObjectGroup

} tmx_container_type_t;


typedef struct tmx_parse_state_s
{
	dp_model_t * mod;

	// current container, possibly none
	tmx_container_type_t container;

	// current layer or objectgroup
	char layer_name[64];

	// these are needed to convert object coordinates (in pixels) to real coords
	int tile_width;
	int tile_height;

	// true if we are parsing a <data> element
	int reading_data;

	// for reading tile data, this is current position
	int cur_tile_x;
	int cur_tile_y;

	// true when parsing a <object> element
	int reading_object;

	// current pointer in entity string buffer
	char *ent_s;
	char *ent_end;

	// a pending light entity (while processing an normal object like a wall torch)
	int pending_light;

	vec3_t pending_origin;
	vec3_t pending_color;
	int    pending_style;

} tmx_parse_state_t;


static void TMX_EntityPrintf(tmx_parse_state_t *st, const char *fmt, ...)
{
	va_list argptr;
	char line[512];

	size_t line_len;
	size_t remain;

	va_start(argptr, fmt);
	dpvsnprintf(line, sizeof(line), fmt, argptr);
	va_end(argptr);

	line_len = strlen(line);
	remain = (size_t)(st->ent_end - st->ent_s);

	if (line_len >= remain)
		Host_Error("Mod_TMX_Load: run out of entity string space.\n");

	memcpy(st->ent_s, line, line_len);

	st->ent_s += line_len;
	st->ent_s[0] = 0;

fprintf(stderr, "@@ ENT: %s", line);
}



static void TMX_ParseMapElement(tmx_parse_state_t *st, const char **attr)
{
	model_tmx_t * tmx = &st->mod->tmx;

	int num_tiles;


	for ( ; *attr ; attr += 2)
	{
		const char *name  = attr[0];
		const char *value = attr[1];

		if (strcmp(name, "width") == 0)
			tmx->width = atoi(value);
		else if (strcmp(name, "height") == 0)
			tmx->height = atoi(value);
		else if (strcmp(name, "tilewidth") == 0)
			st->tile_width = atoi(value);
		else if (strcmp(name, "tileheight") == 0)
			st->tile_height = atoi(value);
	}

	// verify map size

	if (tmx->width < 2 || tmx->height < 2)
		Host_Error("Mod_TMX_Load: map size %dx%d is too small (must be at least 2x2)\n",
				tmx->width, tmx->height);

	if (tmx->width > MAX_TMX_SIZE || tmx->height > MAX_TMX_SIZE)
		Host_Error("Mod_TMX_Load: map size %dx%d is too large (must be under %dx%d)\n",
				tmx->width, tmx->height, MAX_TMX_SIZE, MAX_TMX_SIZE);


	// allocate tile information

	num_tiles = tmx->width * tmx->height;

	tmx->tiles = (tmx_tile_t *)Mem_Alloc(loadmodel->mempool, num_tiles * sizeof(tmx_tile_t));


	// create the worldspawn entity

	TMX_EntityPrintf(st, "{\n");
	TMX_EntityPrintf(st, "  \"classname\" \"worldspawn\"\n");
	TMX_EntityPrintf(st, "}\n");
}


static void TMX_GrabLayerName(tmx_parse_state_t *st, const char **attr)
{
	for ( ; *attr ; attr += 2)
	{
		const char *name  = attr[0];
		const char *value = attr[1];

		if (strcmp(name, "name") == 0)
		{
			strlcpy(st->layer_name, value, sizeof(st->layer_name));
			return;
		}
	}

	Host_Error("Mod_TMX_Load: layer/objectgroup lacks a name\n");
}


static void TMX_CheckEncoding(const char **attr)
{
	for ( ; *attr ; attr += 2)
	{
		const char *name  = attr[0];
		const char *value = attr[1];

		if (strcmp(name, "encoding") == 0 &&
			strcmp(value, "csv") == 0)
		{
			return;  // OK
		}
	}

	Host_Error("Mod_TMX_Load: data not in CSV format\n");
}


static void TMX_ProcessTile(tmx_parse_state_t *st, int gid)
{
	model_tmx_t * tmx = &st->mod->tmx;

	vec3_t origin;
	vec3_t angles;

	int offset = st->cur_tile_y * tmx->width + st->cur_tile_x;

	// check for too much data  [ NOTE: we do not check for insufficient data ]
	if (st->cur_tile_y >= tmx->height)
		Host_Error("Mod_TMX_Load: too much tile data\n");

	// high bits of tile numbers can indicate flipping / transpose.
	// we IGNORE these bits.

	gid &= 0xffffff;


#if 0
fprintf(stderr, "TILE @ (%d %d) in '%s' --> %d\n", st->cur_tile_x, st->cur_tile_y, st->layer_name, gid);
#endif

	// do something with it

	if (gid > 0)
	{
		origin[0] = (st->cur_tile_x + 0.5) * TMX_TILE_SIZE;
		origin[1] = (tmx->height - 1 - st->cur_tile_y + 0.5) * TMX_TILE_SIZE;
		origin[2] = 0;

		VectorSet(angles, 0, 0, 0);

		if (strcmp(st->layer_name, "floorTiles") == 0)
		{
			tmx->tiles[offset].walkable = 1;
			tmx->tiles[offset].visible  = 1;

			TMX_AddStaticEnt(st->mod, "pieces/floor.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "ceilingTiles") == 0 && gid > 0)
		{
			origin[2] = TMX_CEILING_H;

			TMX_AddStaticEnt(st->mod, "pieces/ceiling.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "columns") == 0)
		{
			origin[0] += (TMX_TILE_SIZE / 2);
			origin[1] -= (TMX_TILE_SIZE / 2);

			TMX_AddStaticEnt(st->mod, "pieces/column.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "wallTilesN") == 0)
		{
			origin[1] -= (TMX_TILE_SIZE / 2);
			angles[1]  = 180;

			TMX_AddStaticEnt(st->mod, "pieces/wall.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "wallTilesS") == 0)
		{
			origin[1] += (TMX_TILE_SIZE / 2);

			TMX_AddStaticEnt(st->mod, "pieces/wall.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "wallTilesE") == 0)
		{
			origin[0] -= (TMX_TILE_SIZE / 2);
			angles[1]  = 90;

			TMX_AddStaticEnt(st->mod, "pieces/wall.obj", origin, angles);
		}
		else if (strcmp(st->layer_name, "wallTilesW") == 0)
		{
			origin[0] += (TMX_TILE_SIZE / 2);
			angles[1]  = 270;

			TMX_AddStaticEnt(st->mod, "pieces/wall.obj", origin, angles);
		}
	}

	st->cur_tile_x += 1;

	if (st->cur_tile_x >= tmx->width)
	{
		st->cur_tile_x = 0;
		st->cur_tile_y += 1;
	}
}


static void TMX_OriginForTorch(float real_x, float real_y, float real_z, float wx, float wy, /* out */ vec3_t origin)
{
	// move point away from wall
	if (fabs(wx) < fabs(wy))
		real_x += ((wx < 0) ? -1 : 1) * 20;
	else
		real_y += ((wy > 0) ? -1 : 1) * 20;

	origin[0] = real_x;
	origin[1] = real_y;
	origin[2] = real_z + 40;
}


static void TMX_ProcessObject(tmx_parse_state_t *st, const char **attr)
{
	int pix_x = 0;
	int pix_y = 0;

	float part_x, part_y;
	float real_x, real_y;

	int gid = 0;

	char obj_name[64];

//	int i;
	
	obj_name[0] = 0;

	for ( ; *attr ; attr += 2)
	{
		const char *name  = attr[0];
		const char *value = attr[1];

		if (strcmp(name, "x") == 0)
			pix_x = atoi(value);
		else if (strcmp(name, "y") == 0)
			pix_y = atoi(value);
		else if (strcmp(name, "gid") == 0)
			gid = atoi(value);
		else if (strcmp(name, "name") == 0)
			strlcpy(obj_name, value, sizeof(obj_name));
	}

	if (gid <= 0)
		return;

	part_x = pix_x / (float)st->tile_width  + 0.5;
	part_y = pix_y / (float)st->tile_height - 0.5;

	real_x = TMX_TILE_SIZE * part_x;
	real_y = TMX_TILE_SIZE * (st->mod->tmx.height - part_y);

	switch (gid)
	{
		default:
			Con_Printf("TMX Loader: unknown object gid #%d\n", gid);
			return;

		case 42:  /* player */
			TMX_EntityPrintf(st, "{\n");
			TMX_EntityPrintf(st, "  \"classname\" \"info_player_start\"\n");
			TMX_EntityPrintf(st, "  \"origin\" \"%1.0f %1.0f %1.0f\"\n", real_x, real_y, 0);
			break;

		case 41: /* light */
			TMX_EntityPrintf(st, "{\n");
			TMX_EntityPrintf(st, "  \"classname\" \"light\"\n");
			TMX_EntityPrintf(st, "  \"origin\" \"%1.0f %1.0f %1.0f\"\n", real_x, real_y, TMX_TILE_SIZE / 4.0);
			break;

		case 44: /* wall-mounted thing */
			{
				// align to the nearest wall
				float wx = fmod(part_x, 1.0);
				float wy = fmod(part_y, 1.0);

				float angle = 0;

				float real_z = TMX_TILE_SIZE / 4.0;

				if (wx > 0.5) wx = wx - 1.0;
				if (wy > 0.5) wy = wy - 1.0;

				if (fabs(wx) < fabs(wy))
				{
					real_x -= (wx) * TMX_TILE_SIZE;
					angle = (wx < 0) ? 90 : 270;
				}
				else
				{
					real_y += (wy) * TMX_TILE_SIZE;
					angle = (wy < 0) ? 0 : 180;
				}

				if (! obj_name[0])
					strlcpy(obj_name, "torch", sizeof(obj_name));

				TMX_EntityPrintf(st, "{\n");
				TMX_EntityPrintf(st, "  \"classname\" \"%s\"\n", obj_name);
				TMX_EntityPrintf(st, "  \"origin\" \"%1.0f %1.0f %1.0f\"\n", real_x, real_y, real_z);
				TMX_EntityPrintf(st, "  \"angles\" \"0 %1.0f 0\"\n", angle);

				// possibly create a light source too (for torches)
				st->pending_light = 1;
				TMX_OriginForTorch(real_x, real_y, real_z, wx, wy, st->pending_origin);
				VectorSet(st->pending_color, 1.6, 1.4, 1);
				st->pending_style = 1;
			}
			break;
	}

	st->reading_object = 1;
}


static void TMX_ProcessObjectProperty(tmx_parse_state_t *st, const char **attr)
{
	const char *name;
	const char *value;

	if (! (attr[0] && strcmp(attr[0], "name") == 0))
		return;

	if (! (attr[2] && strcmp(attr[2], "value") == 0))
		return;

	name  = attr[1];
	value = attr[3];
	
	if (strcmp(name, "light") == 0)
	{
		float r = atof(value) * TMX_TILE_SIZE;

		if (st->pending_light > 0)
			st->pending_light = (int)r;
		else
			TMX_EntityPrintf(st, "  \"light\" \"255 255 255 %1.0f\"\n", r);

		return;
	}

	if (st->pending_light > 0)
	{
		if (strcmp(name, "style") == 0)
		{
			st->pending_style = atoi(value);
			return;
		}

		if (strcmp(name, "color") == 0)
		{
			sscanf(value, " %f %f %f ", &st->pending_color[0], &st->pending_color[1], &st->pending_color[2]);
			return;
		}

	}

	// by default : add property directly to entity

	TMX_EntityPrintf(st, "  \"%s\" \"%s\"\n", name, value);
}


static void XMLCALL TMX_xml_start_handler(void *priv, const char *el, const char **attr)
{
	tmx_parse_state_t *st = (tmx_parse_state_t *)priv;

//	model_tmx_t * tmx = &st->mod->tmx;

	switch (st->container)
	{
		case CONTAINER_NONE:
			if (strcmp(el, "map") == 0)
			{
				TMX_ParseMapElement(st, attr);
				return;
			}
			else if (strcmp(el, "tileset") == 0)
			{
				st->container = CONTAINER_Tileset;
				return;
			}
			else if (strcmp(el, "layer") == 0)
			{
				st->container = CONTAINER_Layer;
				TMX_GrabLayerName(st, attr);
				return;
			}
			else if (strcmp(el, "objectgroup") == 0)
			{
				st->container = CONTAINER_ObjectGroup;
				TMX_GrabLayerName(st, attr);
				return;
			}
			break;
			
		case CONTAINER_Tileset:
			/* everything in a tileset is currently ignored */
			return;

		case CONTAINER_Layer:
			if (strcmp(el, "property") == 0)
			{
				// needed ???
			}
			else if (strcmp(el, "data") == 0)
			{
				TMX_CheckEncoding(attr);

				st->reading_data = 1;
				st->cur_tile_x = 0;
				st->cur_tile_y = 0;
				return;
			}
			else if (strcmp(el, "tile") == 0)
				Host_Error("Mod_TMX_Load: data not in CSV format (found <tile> element)\n");

			break;

		case CONTAINER_ObjectGroup:
			if (strcmp(el, "object") == 0)
			{
				TMX_ProcessObject(st, attr);
			}
			else if (strcmp(el, "property") == 0)
			{
				if (st->reading_object)
					TMX_ProcessObjectProperty(st, attr);
			}
			break;
	}

	// ignore unknown or unneeded elements

fprintf(stderr, "TMX: skipping <%s>\n", el);
}


static void XMLCALL TMX_xml_end_handler(void *priv, const char *el)
{
	tmx_parse_state_t *st = (tmx_parse_state_t *)priv;

//	model_tmx_t * tmx = &st->mod->tmx;

	if (strcmp(el, "tileset") == 0  ||
		strcmp(el, "layer") == 0  ||
		strcmp(el, "objectgroup") == 0)
	{
		st->container = CONTAINER_NONE;

		st->layer_name[0] = 0;
		st->reading_data = 0;
		st->reading_object = 0;
		st->pending_light = 0;
	}

	if (strcmp(el, "data") == 0)
		st->reading_data = 0;

	if (strcmp(el, "object") == 0)
	{
		if (st->reading_object)
		{
			// close current entity
			TMX_EntityPrintf(st, "}\n");
		}

		st->reading_object = 0;

		// this check means we only make a light if we got the "light" property
		if (st->pending_light > 1)
		{
			TMX_EntityPrintf(st, "{\n");
			TMX_EntityPrintf(st, "  \"classname\"  \"light\"\n");
			TMX_EntityPrintf(st, "  \"origin\"  \"%1.0f %1.0f %1.0f\"\n", st->pending_origin[0], st->pending_origin[1], st->pending_origin[2]);
			TMX_EntityPrintf(st, "  \"light\"  \"255 255 255 %d\"\n", st->pending_light);
			TMX_EntityPrintf(st, "  \"color\"  \"%1.2f %1.2f %1.2f\"\n", st->pending_color[0], st->pending_color[1], st->pending_color[2]);
			if (st->pending_style)
				TMX_EntityPrintf(st, "  \"style\"  \"%d\"\n", st->pending_style);
			TMX_EntityPrintf(st, "}\n");
		}

		st->pending_light = 0;
	}
}


static void XMLCALL TMX_xml_text_handler(void *priv, const char *s, int len)
{
	tmx_parse_state_t *st = (tmx_parse_state_t *)priv;

//	model_tmx_t * tmx = &st->mod->tmx;

	char number_buf[64];
	int number_len;

	if (! st->reading_data)
		return;

	// NOTE : we assume that numeric values are never chopped up by the
	//        buffers which EXPAT gives us.

	while (len > 0)
	{
		// skip whitespace or odd characters
		if (*s <= ' ' || *s >= 127)
		{
			s++; len--;
			continue;
		}

		// treat commas like whitespace too
		if (*s == ',')
		{
			s++; len--;
			continue;
		}

		// parse an integer value
		number_len = 0;

		while (len > 0 && (isalnum(*s) || *s == '-'))
		{
			if (number_len >= (int)sizeof(number_buf) - 2)
				Host_Error("Mod_TMX_Load: number in <data> chunk too long\n");

			number_buf[number_len++] = *s;

			s++; len--;
		}

		number_buf[number_len] = 0;

		if (! number_len)
			Host_Error("Mod_TMX_Load: non-numeric character in <data> chunk\n");

		TMX_ProcessTile(st, atoi(number_buf));
	}
}


void Mod_TMX_Load(dp_model_t *mod, void *buffer, void *bufferend)
{
	char materialname[MAX_QPATH];
	int i, j, l, numvertices, firstvertex, submodelindex = 0;

	int numtriangles = 0;

	int numtextures = 0;

	float dist, modelradius, modelyawradius, yawradius;
	float mins[3];
	float maxs[3];
	float corner[3];

	unsigned char *data = NULL;
	int *submodelfirstsurface;
	msurface_t *tempsurfaces;

	model_tmx_t *tmx = &mod->tmx;



fprintf(stderr, "Mod_TMX_Load : mod=%p loadmodel=%p\n", mod, loadmodel);



	dpsnprintf(materialname, sizeof(materialname), "%s", loadmodel->name);

	loadmodel->modeldatatypestring = "OBJ";

	loadmodel->type = mod_obj;
	loadmodel->soundfromcenter = true;
	loadmodel->TraceBox = Mod_CollisionBIH_TraceBox;
	loadmodel->TraceBrush = Mod_CollisionBIH_TraceBrush;
	loadmodel->TraceLine = Mod_CollisionBIH_TraceLine;
	loadmodel->TracePoint = Mod_CollisionBIH_TracePoint_Mesh;
	loadmodel->TraceLineAgainstSurfaces = Mod_CollisionBIH_TraceLine;
	loadmodel->PointSuperContents = Mod_CollisionBIH_PointSuperContents_Mesh;
	loadmodel->brush.TraceLineOfSight = NULL;
	loadmodel->brush.SuperContentsFromNativeContents = NULL;
	loadmodel->brush.NativeContentsFromSuperContents = NULL;
	loadmodel->brush.GetPVS = NULL;
	loadmodel->brush.FatPVS = NULL;
	loadmodel->brush.BoxTouchingPVS = NULL;
	loadmodel->brush.BoxTouchingLeafPVS = NULL;
	loadmodel->brush.BoxTouchingVisibleLeafs = NULL;
	loadmodel->brush.FindBoxClusters = NULL;
	loadmodel->brush.LightPoint = NULL;
	loadmodel->brush.FindNonSolidLocation = NULL;
	loadmodel->brush.AmbientSoundLevelsForPoint = NULL;
	loadmodel->brush.RoundUpToHullSize = NULL;
	loadmodel->brush.PointInLeaf = NULL;
	loadmodel->Draw = R_Q1BSP_Draw;
	loadmodel->DrawDepth = R_Q1BSP_DrawDepth;
	loadmodel->DrawDebug = R_Q1BSP_DrawDebug;
	loadmodel->DrawPrepass = R_Q1BSP_DrawPrepass;
	loadmodel->GetLightInfo = R_Q1BSP_GetLightInfo;
	loadmodel->CompileShadowMap = R_Q1BSP_CompileShadowMap;
	loadmodel->DrawShadowMap = R_Q1BSP_DrawShadowMap;
	loadmodel->CompileShadowVolume = R_Q1BSP_CompileShadowVolume;
	loadmodel->DrawShadowVolume = R_Q1BSP_DrawShadowVolume;
	loadmodel->DrawLight = R_Q1BSP_DrawLight;

	if (loadmodel->numskins < 1)
		loadmodel->numskins = 1;

	// make skinscenes for the skins (no groups)
	loadmodel->skinscenes = (animscene_t *)Mem_Alloc(loadmodel->mempool, sizeof(animscene_t) * loadmodel->numskins);
	for (i = 0;i < loadmodel->numskins;i++)
	{
		loadmodel->skinscenes[i].firstframe = i;
		loadmodel->skinscenes[i].framecount = 1;
		loadmodel->skinscenes[i].loop = true;
		loadmodel->skinscenes[i].framerate = 10;
	}

	VectorClear(mins);
	VectorClear(maxs);

	// we always have model 0, i.e. the first "submodel"
	loadmodel->brush.numsubmodels = 1;


	tmx->num_pieces = 0;
	tmx->pieces = (tmx_piece_t *)Mem_Alloc(loadmodel->mempool, MAX_TMX_PIECES * sizeof(tmx_piece_t));

	tmx->ents = NULL;


	loadmodel->brush.entities = (char *)Mem_Alloc(loadmodel->mempool, MAX_TMX_ENT_STRING);


	/* PARSE TMX FILE */


	tmx_parse_state_t parser_state;

	memset(&parser_state, 0, sizeof(parser_state));

	parser_state.mod = mod;

	parser_state.tile_width  = 32;	// defaults
	parser_state.tile_height = 32;

	parser_state.ent_s = (char *) loadmodel->brush.entities;
	parser_state.ent_end = parser_state.ent_s + (MAX_TMX_ENT_STRING - 4);

	parser_state.ent_s[0] = 0;


	XML_Parser p = XML_ParserCreate(NULL);
	if (! p)
		Host_Error("Mod_TMX_Load: out of memory for XML parser\n");

	XML_SetUserData(p, &parser_state);

	XML_SetElementHandler(p, TMX_xml_start_handler, TMX_xml_end_handler);

	XML_SetCharacterDataHandler(p, TMX_xml_text_handler);


	int length = strlen(buffer);

	if (XML_Parse(p, (const char *)buffer, length, 1 /*isFinal*/) == XML_STATUS_ERROR)
	{
		Host_Error("Mod_TMX_Load: XML parse error at line %d:\n%s\n",
			(int) XML_GetCurrentLineNumber(p),
			XML_ErrorString(XML_GetErrorCode(p)));
    }

	XML_ParserFree(p);


	if (! tmx->width)
		Host_Error("Mod_TMX_Load: failed to parse file (no <map> element)\n");

	Con_Printf("TMX Loader: size of map is %dx%d tiles\n", tmx->width, tmx->height);


	mins[0] = -1 * TMX_TILE_SIZE;
	mins[1] = -1 * TMX_TILE_SIZE;
	mins[2] = -1024;

	maxs[0] = (1 + tmx->width)  * TMX_TILE_SIZE;
	maxs[1] = (1 + tmx->height) * TMX_TILE_SIZE;
	maxs[2] = 3072;


	/* END OF TMX PARSING */



	// now that we have the OBJ data loaded as-is, we can convert it

	// copy the model bounds, then enlarge the yaw and rotated bounds according to radius
	VectorCopy(mins, loadmodel->normalmins);
	VectorCopy(maxs, loadmodel->normalmaxs);
	dist = max(fabs(loadmodel->normalmins[0]), fabs(loadmodel->normalmaxs[0]));
	modelyawradius = max(fabs(loadmodel->normalmins[1]), fabs(loadmodel->normalmaxs[1]));
	modelyawradius = dist*dist+modelyawradius*modelyawradius;
	modelradius = max(fabs(loadmodel->normalmins[2]), fabs(loadmodel->normalmaxs[2]));
	modelradius = modelyawradius + modelradius * modelradius;
	modelyawradius = sqrt(modelyawradius);
	modelradius = sqrt(modelradius);
	loadmodel->yawmins[0] = loadmodel->yawmins[1] = -modelyawradius;
	loadmodel->yawmins[2] = loadmodel->normalmins[2];
	loadmodel->yawmaxs[0] = loadmodel->yawmaxs[1] =  modelyawradius;
	loadmodel->yawmaxs[2] = loadmodel->normalmaxs[2];
	loadmodel->rotatedmins[0] = loadmodel->rotatedmins[1] = loadmodel->rotatedmins[2] = -modelradius;
	loadmodel->rotatedmaxs[0] = loadmodel->rotatedmaxs[1] = loadmodel->rotatedmaxs[2] =  modelradius;
	loadmodel->radius = modelradius;
	loadmodel->radius2 = modelradius * modelradius;

	// allocate storage for triangles
	loadmodel->surfmesh.data_element3i = (int *)Mem_Alloc(loadmodel->mempool, numtriangles * sizeof(int[3]));
	// allocate vertex hash structures to build an optimal vertex subset

	// gather surface stats for assigning vertex/triangle ranges
	firstvertex = 0;
	loadmodel->num_surfaces = 0;
	// allocate storage for the worst case number of surfaces, later we resize
	tempsurfaces = (msurface_t *)Mem_Alloc(loadmodel->mempool, numtextures * loadmodel->brush.numsubmodels * sizeof(msurface_t));
	submodelfirstsurface = (int *)Mem_Alloc(loadmodel->mempool, (loadmodel->brush.numsubmodels+1) * sizeof(int));

	for (submodelindex = 0;submodelindex < loadmodel->brush.numsubmodels;submodelindex++)
	{
		submodelfirstsurface[submodelindex] = loadmodel->num_surfaces;
	}
	submodelfirstsurface[submodelindex] = loadmodel->num_surfaces;
	numvertices = firstvertex;
	loadmodel->data_surfaces = (msurface_t *)Mem_Realloc(loadmodel->mempool, tempsurfaces, loadmodel->num_surfaces * sizeof(msurface_t));
	tempsurfaces = NULL;

	// allocate storage for final mesh data
	loadmodel->num_textures = numtextures * loadmodel->numskins;
	loadmodel->num_texturesperskin = numtextures;
	data = (unsigned char *)Mem_Alloc(loadmodel->mempool, loadmodel->num_surfaces * sizeof(int) + loadmodel->num_surfaces * loadmodel->numskins * sizeof(texture_t) + numtriangles * sizeof(int[3]) + (numvertices <= 65536 ? numtriangles * sizeof(unsigned short[3]) : 0) + (r_enableshadowvolumes.integer ? numtriangles * sizeof(int[3]) : 0) + numvertices * sizeof(float[14]) + loadmodel->brush.numsubmodels * sizeof(dp_model_t *));
	loadmodel->brush.submodels = (dp_model_t **)data;data += loadmodel->brush.numsubmodels * sizeof(dp_model_t *);
	loadmodel->sortedmodelsurfaces = (int *)data;data += loadmodel->num_surfaces * sizeof(int);
	loadmodel->data_textures = (texture_t *)data;data += loadmodel->num_surfaces * loadmodel->numskins * sizeof(texture_t);
	loadmodel->surfmesh.num_vertices = numvertices;
	loadmodel->surfmesh.num_triangles = numtriangles;
	if (r_enableshadowvolumes.integer)
		loadmodel->surfmesh.data_neighbor3i = (int *)data;data += numtriangles * sizeof(int[3]);
	loadmodel->surfmesh.data_vertex3f = (float *)data;data += numvertices * sizeof(float[3]);
	loadmodel->surfmesh.data_svector3f = (float *)data;data += numvertices * sizeof(float[3]);
	loadmodel->surfmesh.data_tvector3f = (float *)data;data += numvertices * sizeof(float[3]);
	loadmodel->surfmesh.data_normal3f = (float *)data;data += numvertices * sizeof(float[3]);
	loadmodel->surfmesh.data_texcoordtexture2f = (float *)data;data += numvertices * sizeof(float[2]);
	if (loadmodel->surfmesh.num_vertices <= 65536)
		loadmodel->surfmesh.data_element3s = (unsigned short *)data;data += loadmodel->surfmesh.num_triangles * sizeof(unsigned short[3]);

	// set the surface textures to their real values now that we loaded them...
	for (i = 0;i < loadmodel->num_surfaces;i++)
		loadmodel->data_surfaces[i].texture = loadmodel->data_textures + (size_t)loadmodel->data_surfaces[i].texture;

	// make a single combined shadow mesh to allow optimized shadow volume creation
	Mod_Q1BSP_CreateShadowMesh(loadmodel);

	// compute all the mesh information that was not loaded from the file
	if (loadmodel->surfmesh.data_element3s)
		for (i = 0;i < loadmodel->surfmesh.num_triangles*3;i++)
			loadmodel->surfmesh.data_element3s[i] = loadmodel->surfmesh.data_element3i[i];
	Mod_ValidateElements(loadmodel->surfmesh.data_element3i, loadmodel->surfmesh.num_triangles, 0, loadmodel->surfmesh.num_vertices, __FILE__, __LINE__);
	// generate normals if the file did not have them
	if (!VectorLength2(loadmodel->surfmesh.data_normal3f))
		Mod_BuildNormals(0, loadmodel->surfmesh.num_vertices, loadmodel->surfmesh.num_triangles, loadmodel->surfmesh.data_vertex3f, loadmodel->surfmesh.data_element3i, loadmodel->surfmesh.data_normal3f, r_smoothnormals_areaweighting.integer != 0);
	Mod_BuildTextureVectorsFromNormals(0, loadmodel->surfmesh.num_vertices, loadmodel->surfmesh.num_triangles, loadmodel->surfmesh.data_vertex3f, loadmodel->surfmesh.data_texcoordtexture2f, loadmodel->surfmesh.data_normal3f, loadmodel->surfmesh.data_element3i, loadmodel->surfmesh.data_svector3f, loadmodel->surfmesh.data_tvector3f, r_smoothnormals_areaweighting.integer != 0);
	if (loadmodel->surfmesh.data_neighbor3i)
		Mod_BuildTriangleNeighbors(loadmodel->surfmesh.data_neighbor3i, loadmodel->surfmesh.data_element3i, loadmodel->surfmesh.num_triangles);

	// if this is a worldmodel and has no BSP tree, create a fake one for the purpose
	loadmodel->brush.num_visleafs = 1;
	loadmodel->brush.num_leafs = 1;
	loadmodel->brush.num_nodes = 0;
	loadmodel->brush.num_leafsurfaces = loadmodel->num_surfaces;
	loadmodel->brush.data_leafs = (mleaf_t *)Mem_Alloc(loadmodel->mempool, loadmodel->brush.num_leafs * sizeof(mleaf_t));
	loadmodel->brush.data_nodes = (mnode_t *)loadmodel->brush.data_leafs;
	loadmodel->brush.num_pvsclusters = 1;
	loadmodel->brush.num_pvsclusterbytes = 1;
	loadmodel->brush.data_pvsclusters = nobsp_pvs;
	//if (loadmodel->num_nodes) loadmodel->data_nodes = (mnode_t *)Mem_Alloc(loadmodel->mempool, loadmodel->num_nodes * sizeof(mnode_t));
	//loadmodel->data_leafsurfaces = (int *)Mem_Alloc(loadmodel->mempool, loadmodel->num_leafsurfaces * sizeof(int));
	loadmodel->brush.data_leafsurfaces = loadmodel->sortedmodelsurfaces;
	VectorCopy(loadmodel->normalmins, loadmodel->brush.data_leafs->mins);
	VectorCopy(loadmodel->normalmaxs, loadmodel->brush.data_leafs->maxs);

	loadmodel->brush.data_leafs->combinedsupercontents = 0; // FIXME?
	loadmodel->brush.data_leafs->clusterindex = 0;
	loadmodel->brush.data_leafs->areaindex = 0;
	loadmodel->brush.data_leafs->numleafsurfaces = loadmodel->brush.num_leafsurfaces;
	loadmodel->brush.data_leafs->firstleafsurface = loadmodel->brush.data_leafsurfaces;
	loadmodel->brush.data_leafs->numleafbrushes = 0;
	loadmodel->brush.data_leafs->firstleafbrush = NULL;
	loadmodel->brush.supportwateralpha = true;

	if (loadmodel->brush.numsubmodels)
		loadmodel->brush.submodels = (dp_model_t **)Mem_Alloc(loadmodel->mempool, loadmodel->brush.numsubmodels * sizeof(dp_model_t *));

	mod = loadmodel;

	for (i = 0;i < loadmodel->brush.numsubmodels;i++)
	{
		if (i > 0)
		{
			char name[10];
			// duplicate the basic information
			dpsnprintf(name, sizeof(name), "*%i", i);
			mod = Mod_FindName(name, loadmodel->name);
			// copy the base model to this one
			*mod = *loadmodel;
			// rename the clone back to its proper name
			strlcpy(mod->name, name, sizeof(mod->name));
			mod->brush.parentmodel = loadmodel;
			// textures and memory belong to the main model
			mod->texturepool = NULL;
			mod->mempool = NULL;
			mod->brush.GetPVS = NULL;
			mod->brush.FatPVS = NULL;
			mod->brush.BoxTouchingPVS = NULL;
			mod->brush.BoxTouchingLeafPVS = NULL;
			mod->brush.BoxTouchingVisibleLeafs = NULL;
			mod->brush.FindBoxClusters = NULL;
			mod->brush.LightPoint = NULL;
			mod->brush.AmbientSoundLevelsForPoint = NULL;
		}
		mod->brush.submodel = i;
		if (loadmodel->brush.submodels)
			loadmodel->brush.submodels[i] = mod;

		// make the model surface list (used by shadowing/lighting)
		mod->firstmodelsurface = submodelfirstsurface[i];
		mod->nummodelsurfaces = submodelfirstsurface[i+1] - submodelfirstsurface[i];
		mod->firstmodelbrush = 0;
		mod->nummodelbrushes = 0;
		mod->sortedmodelsurfaces = loadmodel->sortedmodelsurfaces + mod->firstmodelsurface;
		Mod_MakeSortedSurfaces(mod);

		VectorClear(mod->normalmins);
		VectorClear(mod->normalmaxs);
		l = false;
		for (j = 0;j < mod->nummodelsurfaces;j++)
		{
			const msurface_t *surface = mod->data_surfaces + j + mod->firstmodelsurface;
			const float *v = mod->surfmesh.data_vertex3f + 3 * surface->num_firstvertex;
			int k;
			if (!surface->num_vertices)
				continue;
			if (!l)
			{
				l = true;
				VectorCopy(v, mod->normalmins);
				VectorCopy(v, mod->normalmaxs);
			}
			for (k = 0;k < surface->num_vertices;k++, v += 3)
			{
				mod->normalmins[0] = min(mod->normalmins[0], v[0]);
				mod->normalmins[1] = min(mod->normalmins[1], v[1]);
				mod->normalmins[2] = min(mod->normalmins[2], v[2]);
				mod->normalmaxs[0] = max(mod->normalmaxs[0], v[0]);
				mod->normalmaxs[1] = max(mod->normalmaxs[1], v[1]);
				mod->normalmaxs[2] = max(mod->normalmaxs[2], v[2]);
			}
		}
		corner[0] = max(fabs(mod->normalmins[0]), fabs(mod->normalmaxs[0]));
		corner[1] = max(fabs(mod->normalmins[1]), fabs(mod->normalmaxs[1]));
		corner[2] = max(fabs(mod->normalmins[2]), fabs(mod->normalmaxs[2]));
		modelradius = sqrt(corner[0]*corner[0]+corner[1]*corner[1]+corner[2]*corner[2]);
		yawradius = sqrt(corner[0]*corner[0]+corner[1]*corner[1]);
		mod->rotatedmins[0] = mod->rotatedmins[1] = mod->rotatedmins[2] = -modelradius;
		mod->rotatedmaxs[0] = mod->rotatedmaxs[1] = mod->rotatedmaxs[2] = modelradius;
		mod->yawmaxs[0] = mod->yawmaxs[1] = yawradius;
		mod->yawmins[0] = mod->yawmins[1] = -yawradius;
		mod->yawmins[2] = mod->normalmins[2];
		mod->yawmaxs[2] = mod->normalmaxs[2];
		mod->radius = modelradius;
		mod->radius2 = modelradius * modelradius;

		// this gets altered below if sky or water is used
		mod->DrawSky = NULL;
		mod->DrawAddWaterPlanes = NULL;

		for (j = 0;j < mod->nummodelsurfaces;j++)
			if (mod->data_surfaces[j + mod->firstmodelsurface].texture->basematerialflags & MATERIALFLAG_SKY)
				break;
		if (j < mod->nummodelsurfaces)
			mod->DrawSky = R_Q1BSP_DrawSky;

		for (j = 0;j < mod->nummodelsurfaces;j++)
			if (mod->data_surfaces[j + mod->firstmodelsurface].texture->basematerialflags & (MATERIALFLAG_WATERSHADER | MATERIALFLAG_REFRACTION | MATERIALFLAG_REFLECTION | MATERIALFLAG_CAMERA))
				break;
		if (j < mod->nummodelsurfaces)
			mod->DrawAddWaterPlanes = R_Q1BSP_DrawAddWaterPlanes;

		Mod_MakeCollisionBIH(mod, true, &mod->collision_bih);
		mod->render_bih = mod->collision_bih;

		// generate VBOs and other shared data before cloning submodels
		if (i == 0)
			Mod_BuildVBOs();
	}

	mod = loadmodel;
	Mem_Free(submodelfirstsurface);
}



void TMX_MarkPiecesUsed(dp_model_t *mod)
{
	int i;

	for (i = 0 ; i < mod->tmx.num_pieces ; i++)
	{
		if (mod->tmx.pieces[i].model)
			mod->tmx.pieces[i].model->used = true;
	}
}


void TMX_LoadPieces(dp_model_t *mod)
{
	int i;

	// andrewj: always re-lookup the models.
	// [ previously I had a check like "if (already loaded) return;" but
	//   it did not work properly when the same map was re-entered. ]

	for (i = 0 ; i < mod->tmx.num_pieces ; i++)
	{
fprintf(stderr, "TMX : loading '%s'\n", mod->tmx.pieces[i].model_name);

		mod->tmx.pieces[i].model = Mod_ForName(mod->tmx.pieces[i].model_name,
			false, developer.integer > 0, NULL);
	}
}


//------------------------------------------------------------------------


static void TMX_LinkStaticEnt(dp_model_t *mod, tmx_static_entity_t *ent)
{
	entity_render_t *render = &ent->render;


	memset(render, 0, sizeof(render));


	render->model = ent->piece->model;

	Matrix4x4_CreateFromQuakeEntity(&render->matrix, ent->origin[0], ent->origin[1], ent->origin[2],
		ent->angles[0], ent->angles[1], ent->angles[2], ent->scale);

	render->alpha = 1;

	VectorSet(render->colormod, 1, 1, 1);
	VectorSet(render->glowmod,  1, 1, 1);

	render->flags = RENDER_SHADOW;

	if(!r_fullbright.integer)
		render->flags |= RENDER_LIGHT;

	render->allowdecals = true;

	CL_UpdateRenderEntity(render);

	if (r_refdef.scene.numentities < r_refdef.scene.maxentities)
		r_refdef.scene.entities[r_refdef.scene.numentities++] = render;
}


//
// this runs on client, adds visible map pieces to the set of render entities
//
void TMX_CL_RelinkPieces(dp_model_t *mod)
{
	tmx_static_entity_t *ent;

	for (ent = mod->tmx.ents ; ent ; ent = ent->next)
	{
		if (! ent->piece->model)
			return;

		TMX_LinkStaticEnt(mod, ent);
	}
}

