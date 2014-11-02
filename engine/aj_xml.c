
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

//------------------------------------------------------------------------
//   STRING MANAGEMENT
//------------------------------------------------------------------------

// usual size of each string buffer  [ FIXME : should be 65536 ]
#define STRING_BUFFER_SIZE  256

typedef struct aj_xml_string_buffer_s
{
	// buffer containing strings.
	// each string is NUL-terminated.
	char * buffer;

	int used;	// used characters in buffer (including last NUL)
	int total;	// total size of buffer

	struct aj_xml_string_buffer_s * next;

} aj_xml_string_buffer_t;


//------------------------------------------------------------------------
//   NODE MANAGEMENT
//------------------------------------------------------------------------

// usual # of nodes in each node buffer   [ FIXME should be 256 ]
#define NODE_BUFFER_SIZE	16

typedef struct aj_xml_node_buffer_s
{
	// buffer containing nodes.
	aj_xml_node_t * buffer;

	int used;	// used  # of nodes
	int total;	// total # of nodes in buffer

	struct aj_xml_node_buffer_s * next;

} aj_xml_node_buffer_t;



//------------------------------------------------------------------------
//   REAL ROOT NODE
//------------------------------------------------------------------------

typedef struct aj_xml_real_root_s
{
	aj_xml_node_t  fake_root;

	aj_xml_string_buffer_t  * str_bufs;

	aj_xml_node_buffer_t * node_bufs;

} aj_xml_real_root_t;



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
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
