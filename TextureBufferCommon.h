// ===========================================================================
//	TextureBufferCommon			 (C)2010 Mark F. Coniglio. All rights reserved.
// ===========================================================================
//
// TextureBuffers define an OpenGL texture map buffer

#ifndef _H_TextureBufferCommon
#define _H_TextureBufferCommon

#ifdef _H_CGLTexture
	typedef class CGLTexture*			IzzyTexture;
#else
	typedef struct OpaqueCGLTexture*	IzzyTexture;
#endif

#include "ValueCommon.h"
#include "IsadoraTypes.h"

// Magic Value to identify valid image buffers...
#define kTextureBufferMagic			0x12345678

#define	kTextureBufferDataType		FOUR_CHAR_CODE('txtr')

// ===========================================================================
// TextureBuffer struct

struct TextureBuffer
{
	DataValueInfo	mInfo;					// our data value info struct - required
	UInt32			mMagic;					// magic value
	IzzyTexture		mTexture;				// pointer to the texture
	StageIndexT		mTargetStageIndex0;		// destination stage for the buffer
};

typedef struct TextureBuffer	TextureBuffer, *TextureBufferPtr;

// ===========================================================================
// FUNCTIONS

void
TextureBuffer_Init(
	TextureBufferPtr	inTextureBuffer);

void
TextureBuffer_Uninit(
	TextureBufferPtr	inTextureBuffer);

void
TextureBuffer_Dispose(
	TextureBufferPtr	inTextureBuffer);

void
TextureBuffer_GetDimensions(
	TextureBufferPtr	inTextureBuffer,
	UInt32*				outWidth,
	UInt32*				outHeight);

#if (DEBUG || CHECK_TEXTURE_BUFFER_MAGIC)
	#define TextureBuffer_CheckMagic(tb)	Assert_(tb == NULL || (tb)->mMagic == kTextureBufferMagic)
#else
	#define TextureBuffer_CheckMagic(tb)	{ }
#endif

#endif	// #if _H_TextureBufferCommon
