// ---------------------------------------------------------------------------------
// PluginInfo struct
// ---------------------------------------------------------------------------------
// ### This structure neeeds to contain all variables used by your plugin. Memory for
// this struct is allocated during the CreateActor function, and disposed during
// the DisposeActor function, and is private to each copy of the plugin.
//
// If your plugin needs global data, declare them as static variables within this
// file. Any static variable will be global to all instantiations of the plugin.

#include "IsadoraTypes.h"
#include "IsadoraCallbacks.h"
#include "ImageBufferCommon.h"
#include "ImageBufferUtil.h"

@class PacketHandler;
@class ImageBufferUpdater;

typedef struct PluginInfoStruct {
    
	ActorInfo*				mActorInfoPtr;		// our ActorInfo Pointer - set during create actor function
	MessageReceiverRef		mMessageReceiver;	// pointer to our message receiver reference
	Boolean					mNeedsDraw;			// set to true when the video output needs to be drawn
	
	
    ImageBufferPtr          mImageOutputBufferPtr;	// we only need an output buffer

//	ImageBufferMap			mImageBufferMap;	// used by most video plugins -- see about ImageBufferMaps above
	
    SInt32                  mPort;
	Boolean					mEnabled;
    String*                 mServiceName;
    
    
    
    PacketHandler*          packetHandler;
    ImageBufferUpdater*     imageBufferUpdater;
    
	
} PluginInfo;
