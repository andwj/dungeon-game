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


#define TMX_TILE_SIZE	40.0

#define MAX_TMX_ENT_STRING	1048576


/* TEST CRUD !!!! */

static const char test_entity_crud[] =
"{\n"
"  \"classname\" \"worldspawn\"\n"
"}\n"
"{\n"
"  \"classname\" \"info_player_start\"\n"
"  \"origin\" \"224 224 40\"\n"
"  \"angle\" \"215\"\n"
"}\n"
"{\n"
"  \"classname\" \"test_floor\"\n"
"  \"origin\" \"224 224 0\"\n"
"}\n"
"\n"
"{\n"
"  \"classname\" \"light\"\n"
"  \"origin\" \"246 450 90\"\n"
"  \"light\" \"255 255 255 2000\"\n"
"  \"color\" \"1.6 1.4 1.0\"\n"
"  \"style\" \"1\"\n"
"}\n";



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

	// link in
	ent->next = mod->tmx.ents;
	mod->tmx.ents = ent;
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


	/* TODO: PARSE FILE !!! */

	mod->tmx.width  = 40;
	mod->tmx.height = 40;

	int num_tiles = mod->tmx.width * mod->tmx.height;

	mod->tmx.tiles = (tmx_tile_t *)Mem_Alloc(loadmodel->mempool, num_tiles * sizeof(tmx_tile_t));

	mod->tmx.num_pieces = 0;
	mod->tmx.pieces = (tmx_piece_t *)Mem_Alloc(loadmodel->mempool, MAX_TMX_PIECES * sizeof(tmx_piece_t));

	mod->tmx.ents = NULL;


	mins[0] = -1 * TMX_TILE_SIZE;
	mins[1] = -1 * TMX_TILE_SIZE;
	mins[2] = -1024;

	maxs[0] = (1 + mod->tmx.width)  * TMX_TILE_SIZE;
	maxs[1] = (1 + mod->tmx.height) * TMX_TILE_SIZE;
	maxs[2] = 3072;


// MORE TEST STUFF

vec3_t test_origin;
vec3_t test_angles;

VectorSet(test_origin, 0, 0, 0);
VectorSet(test_angles, 0, 0, 0);
TMX_AddStaticEnt(mod, "pieces/column.obj", test_origin, test_angles);

VectorSet(test_origin, 100, 0, 0);
TMX_AddStaticEnt(mod, "pieces/column.obj", test_origin, test_angles);

VectorSet(test_origin, 200, 0, 0);
TMX_AddStaticEnt(mod, "pieces/column.obj", test_origin, test_angles);



int test_len = strlen(test_entity_crud);
loadmodel->brush.entities = (char *)Mem_Alloc(loadmodel->mempool, test_len + 1);
memcpy(loadmodel->brush.entities, test_entity_crud, test_len + 1);



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



void TMX_LoadPieces(dp_model_t *mod)
{
	int i;

	// already loaded?
	if (mod->tmx.loaded_pieces)
		return;

	for (i = 0 ; i < mod->tmx.num_pieces ; i++)
	{
fprintf(stderr, "TMX : loading '%s'\n", mod->tmx.pieces[i].model_name);

		mod->tmx.pieces[i].model = Mod_ForName(mod->tmx.pieces[i].model_name,
			false, developer.integer > 0, NULL);
	}

	mod->tmx.loaded_pieces = true;
}


//------------------------------------------------------------------------


static int e_index = 0;  // FIXME TEMP CRUD


static void TMX_LinkStaticEnt(dp_model_t *mod, tmx_static_entity_t *ent)
{
	float scale = 100;


	// TEMP!!!
	static entity_render_t  render_set[10];

	if (e_index >= 10) return;

	entity_render_t *render = &render_set[e_index++];


	memset(render, 0, sizeof(render));


	render->model = ent->piece->model;

	Matrix4x4_CreateFromQuakeEntity(&render->matrix, ent->origin[0], ent->origin[1], ent->origin[2],
		ent->angles[0], ent->angles[1], ent->angles[2], scale);

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

	e_index = 0;

	for (ent = mod->tmx.ents ; ent ; ent = ent->next)
	{
		if (! ent->piece->model)
			return;

		TMX_LinkStaticEnt(mod, ent);
	}
}

