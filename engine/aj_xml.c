
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
#include <string.h>
#include <ctype.h>


//------------------------------------------------------------------------
//   STRUCTURES
//------------------------------------------------------------------------

// usual size of each string buffer  [ FIXME : should be 65536 ]
#define STRING_BUFFER_SIZE  256

// strings over this length we do not bother finding an existing one  [ FIXME : should be 128 ]
#define STRING_SHORT_LEN  8

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

	// the empty string
	char empty_str[4];

} aj_xml_real_root_t;


//------------------------------------------------------------------------
//   STRING MANAGEMENT
//------------------------------------------------------------------------

#define OUT_OF_MEMORY(what)  do { return NULL; } while (0)


static const char * aj_xml_FindString(aj_xml_real_root_t * root, const char *str, size_t len)
{
	aj_xml_string_buffer_t * buf;

	for (buf = root->str_bufs ; buf ; buf = buf->next)
	{
		int pos = 0;

		while (pos < buf->used)
		{
			const char *check = &buf->buffer[pos];

			if (check[len] == 0 /* same length? */ &&
				memcmp(check, str, len) == 0 /* same data? */)
			{
				return check;  // OK
			}

			pos = pos + (int)strlen(check) + 1;
		}
	}

	return NULL;	// does not exist
}


static aj_xml_node_t * aj_xml_AllocateString(aj_xml_real_root_t * root, int full_len)
{
	// Note: 'full_len' includes NUL termination.

	size_t new_size;
	aj_xml_string_buffer_t * new_buf;
	aj_xml_string_buffer_t * old_buf;

	// if string is very long, allocate a whole buffer just for it instead of
	// wasting a lot of space in an existing buffer (plus it may not even fit
	// inside a normal buffer).
	if (full_len > STRING_BUFFER_SIZE / 16)
	{
		new_size = sizeof(aj_xml_string_buffer_t) + (size_t)full_len;

		new_buf = (aj_xml_string_buffer_t *) calloc(new_size);
		if (! new_buf)
			OUT_OF_MEMORY("string buffer");

		new_buf->used  = full_len;
		new_buf->total = full_len;

		// link it in
		new_buf->next = root->str_bufs;
		root->str_bufs = new_buf;

		return &new_buf->buffer[0];
	}

	// see if we can re-use an existing buffer
	// [ we try them all! ]

	for (old_buf = root->str_bufs ; old_buf ; old_buf = old_buf->next)
	{
		if (old_buf->used + full_length <= old_buf->total)
		{
			// OK

			int pos = old_buf->used;

			old_buf->used += full_len;

			return &old_buf->buffer[pos];
		}
	}
	

	// no buffer we can re-use : allocate a new one

	{
		// this slightly overestimates how much memory we need
		new_size = sizeof(aj_xml_string_buffer_t) + STRING_BUFFER_SIZE;

		new_buf = (aj_xml_string_buffer_t *) calloc(new_size);
		if (! new_buf)
			OUT_OF_MEMORY("string buffer");

		new_buf->used  = full_len;
		new_buf->total = STRING_BUFFER_SIZE;

		// link it in
		new_buf->next = root->str_bufs;
		root->str_bufs = new_buf;

		return &new_buf->buffer[0];
	}
}


static const char * aj_xml_Strndup(aj_xml_real_root_t * root, const char *buf, size_t len)
{
	const char * new_str;

	if (len == 0)
		return root->empty_str;

	// only look for same strings when length is fairly short

	if (len <= STRING_SHORT_LEN)
	{
		const char *exist_str = aj_xml_FindString(root, buf, len);

		if (exist_str)
			return exist_str;
	}

	new_str = aj_xml_AllocateString(root, len + 1);
	if (! new_str)
		return NULL;

	memcpy(new_str, buf, len);
	new_str[len] = 0;

	return new_str;
}


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
			OUT_OF_MEMORY("node buffer");

		new_buf->used  = 0;
		new_buf->total = NODE_BUFFER_SIZE;

		// link it in

		new_buf->next   = root->node_bufs;
		root->node_bufs = new_buf;
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

#define SKIP_WHITESPACE(buf)  while (isspace(*buf)) buf++

#define SYNTAX_ERROR(msg)  do { return NULL; } while(0)


int aj_xml_ParseAttribute(aj_xml_real_root_t *root, aj_xml_node_t *node)
{
	// returns 1 on success, 0 if hit end of element, -1 on error

	// TODO
}


aj_xml_node_t * aj_xml_ParseElement(aj_xml_real_root_t *root, const char *buf, 
	aj_xml_node_t * exist_node, int need_bracket);
{
	aj_xml_node_t *node;

	// returns 0 on success, negative value on error

	if (need_bracket)
	{
		SKIP_WHITESPACE(buf);

		if (*buf != '<')
			SYNTAX_ERROR("missing < at start");

		buf++;
	}

	SKIP_WHITESPACE(buf);

	if (exist_node)
		node = exist_node;
	else
	{
		node = aj_xml_AllocateNode(node);
		if (! node)
			return NULL;
	}

	// TODO : parse element name

	// TODO : parse attributes

	// TODO : parse '/' at end

	// TODO : parse text and children nodes (unless '/' at end)
}


//------------------------------------------------------------------------
//   API FUNCTIONS
//------------------------------------------------------------------------

aj_xml_node_t * aj_xml_Parse(const char *buffer)
{
	aj_xml_node_t *node;

	// create the root node

	aj_xml_real_root_t * root = calloc(sizeof(aj_xml_real_root_t));
	if (! root)
		return OUT_OF_MEMORY("root node");

	node = aj_xml_ParseElement(root, buffer, &root->fake_root, 1 /* need_bracket */);
	
	if (! node)
	{
		aj_xml_Free(root);
		return NULL;
	}

	return &root->fake_root;
}


void aj_xml_Free(aj_xml_node_t * root)
{
	aj_xml_real_root_t * real_root = (aj_xml_real_root_t *)root;

	aj_xml_FreeStringBufs(real_root->node_bufs);
	aj_xml_FreeNodeBufs(real_root->node_bufs);

	memset((void *)root, -1, sizeof(aj_xml_real_root_t));

	free((void *)real_root);
}

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
