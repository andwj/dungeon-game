
/*******************
   AJ XML PARSER
********************

by Andrew Apted, November 2014


The code herein is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this code.  Use at your own risk.

Permission is granted to anyone to use this code for any purpose,
including commercial applications, and to freely redistribute and
modify it.  An acknowledgement would be nice, but is not required.


__ABOUT__

This is an incredibly simple, naive, slow, inefficent, non-conforming,
non-validating, non-everything parser for XML files, written in C.
If that is not what you want or need, you can find extremely good XML
parsing libraries out there (mostly in C++ mind you).

*/

#include <stdlib.h>


//------------------------------------------------------------------------
//   STRUCTURES
//------------------------------------------------------------------------

// usual size of each string buffer  [ FIXME : should be 65536 ]
#define STRING_BUFFER_SIZE  256

typedef struct aj_xml_string_buffer_s
{
	int used;	// used characters in buffer (including last NUL)
	int total;	// total size of buffer

	struct aj_xml_string_buffer_s * next;

	// buffer containing strings.
	// each string is NUL-terminated.
	// NOTE: this array will contain [total] elements
	char buffer[4];

} aj_xml_string_buffer_t;


// usual # of nodes in each node buffer   [ FIXME should be 256 ]
#define NODE_BUFFER_SIZE	10

typedef struct aj_xml_node_buffer_s
{
	int used;	// used  # of nodes
	int total;	// total # of nodes in buffer

	struct aj_xml_node_buffer_s * next;

	aj_xml_node_t buffer[1];	// actually contains [total] elements

} aj_xml_node_buffer_t;


typedef struct aj_xml_real_root_s
{
	aj_xml_node_t  fake_root;

	aj_xml_string_buffer_t  * str_bufs;

	aj_xml_node_buffer_t * node_bufs;

} aj_xml_real_root_t;


//------------------------------------------------------------------------
//   STRING MANAGEMENT
//------------------------------------------------------------------------



static void aj_xml_FreeStringBufs(aj_xml_real_root_t * root)
{
	while (root->str_bufs)
	{
		aj_xml_string_buffer_t *buf = root->str_bufs;

		root->str_bufs = buf->next;

		free((void *)buf);
	}
}



//------------------------------------------------------------------------
//   NODE MANAGEMENT
//------------------------------------------------------------------------

static aj_xml_node_t * aj_xml_AllocateNode(aj_xml_real_root_t * root)
{
	if (! root->node_bufs || root->node_bufs->used >= root->node_bufs->total)
	{
		// this slightly overestimates how much memory we need
		size_t size = sizeof(aj_xml_node_buffer_t) + NODE_BUFFER_SIZE * sizeof(aj_xml_node_t);

		aj_xml_node_buffer_t * new_buf = (aj_xml_node_buffer_t *) calloc(size);

		if (! new_buf)
			return;

		new_buf->used  = 0;
		new_buf->total = NODE_BUFFER_SIZE;

		// link it in

		root->node_bufs = new_buf;
		new_buf->next   = root;
	}

	int index = root->node_bufs->used;

	root->node_bufs->used += 1;

	return &root->node_bufs->buffer[index];
}


static void aj_xml_FreeNodeBufs(aj_xml_real_root_t * root)
{
	while (root->node_bufs)
	{
		aj_xml_node_buffer_t *buf = root->node_bufs;

		root->node_bufs = buf->next;

		free((void *)buf);
	}
}


//------------------------------------------------------------------------
//   PARSING STUFF
//------------------------------------------------------------------------



//------------------------------------------------------------------------
//   API FUNCTIONS
//------------------------------------------------------------------------


aj_xml_node_t * aj_xml_Parse(const char *buffer)
{
}


void aj_xml_Free(aj_xml_node_t * root)
{
	aj_xml_real_root_t * real_root = (aj_xml_real_root_t *)root;

	aj_xml_FreeStringBufs(real_root->node_bufs);
	aj_xml_FreeNodeBufs(real_root->node_bufs);
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
