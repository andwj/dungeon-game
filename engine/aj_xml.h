
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

#ifndef __AJ_XML_PARSER_API__
#define __AJ_XML_PARSER_API__

//
// this is everything : a document, an element, or an attribute.
//
typedef struct aj_xml_node_s
{
	// if name is "", this is a continuing text element (i.e. text after
	// some other self-contained elements).  Never NULL.
	const char *name;

	// for elements, this is the following text ("" for none).
	// Never NULL.
	const char *value;

	struct aj_xml_node_s *children;
	struct aj_xml_node_s *attributes;

	// next (sibling) node or attribute
	struct aj_xml_node_s *next;

} aj_xml_node_t;


//
// Takes a NUL-terminated string and parses it into a tree structure
// consisting of aj_xml_node_ts.  Returns NULL if the buffer does not
// appear to be an XML file, or a serious parsing error occurs, or we
// run out of memory.
//
aj_xml_node_t * aj_xml_Parse(const char *buffer);


//
// Frees the whole tree structure returned from aj_xml_Parse().
// Cannot be used on sub-elements (the root node is really larger and
// contains the allocated nodes and strings).
//
void aj_xml_Free(aj_xml_node_t * root);


//
// This is for testing
//
void aj_xml_Dump(aj_xml_node_t * root);

#endif  /* __AJ_XML_PARSER_API__ */

//--- editor settings ---
// vi:ts=4:sw=4:noexpandtab
