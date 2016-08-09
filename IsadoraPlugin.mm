// ===========================================================================
//	Isadora Demo Plugin			   ©2003 Mark F. Coniglio. All rights reserved.
// ===========================================================================
//
//	IMPORTANT: This source code ("the software") is supplied to you in
//	consideration of your agreement to the following terms. If you do not
//	agree to the terms, do not install, use, modify or redistribute the
//	software.
//
//	Mark Coniglio (dba TroikaTronix) grants you a personal, non exclusive
//	license to use, reproduce, modify this software with and to redistribute it,
//	with or without modifications, in source and/or binary form. Except as
//	expressly stated in this license, no other rights are granted, express
//	or implied, to you by TroikaTronix.
//
//	This software is provided on an "AS IS" basis. TroikaTronix makes no
//	warranties, express or implied, including without limitation the implied
//	warranties of non-infringement, merchantability, and fitness for a
//	particular purpurse, regarding this software or its use and operation
//	alone or in combination with your products.
//
//	In no event shall TroikaTronix be liable for any special, indirect, incidental,
//	or consequential damages arising in any way out of the use, reproduction,
//	modification and/or distribution of this software.
//
// ===========================================================================
//
// CUSTOMIZING THIS SOURCE CODE
// To customize this file, search for the text ###. All of the places where
// you will need to customize the file are marked with this pattern of
// characters.
//
// ABOUT IMAGE BUFFER MAPS:
//
// The ImageBufferMap structure, and its accompanying functions,
// exists as a convenience to those writing video processing plugins.
//
// Basically, an image buffer contains an arbitrary number of input and
// output buffers (in the form of ImageBuffers). The ImageBufferMap code
// will automatically create intermediary buffers if needed, so that the
// size and depth of the source image buffers sent to your callback are
// the same for all buffers.
//
// Typically, the ImageBufferMap is created in your CreateActor function,
// and dispose in the DiposeActor function.

// ---------------------------------------------------------------------------------
// INCLUDES
// ---------------------------------------------------------------------------------

#include "IsadoraTypes.h"
#include "IsadoraCallbacks.h"
#include "ImageBufferUtil.h"
#include "PluginDrawUtil.h"

// STANDARD INCLUDES
#include <string.h>
#include <stdio.h>

// ---------------------------------------------------------------------------------
// MacOS Specific
// ---------------------------------------------------------------------------------
#if TARGET_OS_MAC
#define EXPORT_
#endif

// ---------------------------------------------------------------------------------
// Win32  Specific
// ---------------------------------------------------------------------------------
#if TARGET_OS_WIN32

#include <windows.h>

#define EXPORT_ __declspec(dllexport)

#ifdef __cplusplus
extern "C" {
#endif
    
	BOOL WINAPI DllMain ( HINSTANCE hInst, DWORD wDataSeg, LPVOID lpvReserved );
    
#ifdef __cplusplus
}
#endif

BOOL WINAPI DllMain (
                     HINSTANCE	/* hInst */,
                     DWORD		wDataSeg,
                     LPVOID		/* lpvReserved */)
{
	switch(wDataSeg) {
            
        case DLL_PROCESS_ATTACH:
            return 1;
            break;
        case DLL_PROCESS_DETACH:
            break;
            
        default:
            return 1;
            break;
	}
	return 0;
}

#endif

// ---------------------------------------------------------------------------------
//	Exported Function Definitions
// ---------------------------------------------------------------------------------

#ifdef __cplusplus
extern "C" {
#endif
    
    EXPORT_ void GetActorInfo(void* inParam, ActorInfo* outActorParams);
    
#ifdef __cplusplus
}
#endif

// ---------------------------------------------------------------------------------
//	FORWARD DECLARTIONS
// ---------------------------------------------------------------------------------
static void
ReceiveMessage(
               IsadoraParameters*	ip,
               MessageMask			inMessageMask,
               PortIndex			inPortIndex1,
               const MsgData*		inData,
               UInt32				inLen,
               long				inRefCon);

// ---------------------------------------------------------------------------------
// GLOBAL VARIABLES
// ---------------------------------------------------------------------------------
// ### Declare global variables, common to all instantiations of this plugin here


// A handy macro for casting the mActorDataPtr to PluginInfo*
#if __cplusplus
#define	GetPluginInfo_(actorDataPtr)		static_cast<PluginInfo*>((actorDataPtr)->mActorDataPtr);
#else
#define	GetPluginInfo_(actorDataPtr)		(PluginInfo*)((actorDataPtr)->mActorDataPtr);
#endif

#import "PluginInfo.h"
#import "PacketHandler.h"
#import "ImageBufferUpdater.h"

//static PacketHandler* packetHandler = nil;
//static ImageBufferUpdater* imageBufferUpdater = nil;

void enableNetworking(IsadoraParameters* ip, PluginInfo* info) {
    
    if (info->packetHandler != nil) return;
    
    
    if (info->mServiceName->useCount > 0) {
        info->imageBufferUpdater = [[ImageBufferUpdater alloc] initWithIsadoraParameters: ip
                                                                        pluginInfo: info];
        
        info->packetHandler = [PacketHandler new];
        info->packetHandler.delegate = info->imageBufferUpdater;
        
        NSString* serviceID = [NSString stringWithUTF8String:info->mServiceName->strData];
        
        // NOTE: this returns YES/NO, we may be able to use this...
        [info->packetHandler startWithPortNumber:(info->mPort + 49152) serviceID:serviceID];
    }
}

void disableNetworking(PluginInfo* info) {
    if (info->packetHandler == nil) return;
    
    [info->packetHandler stop];
    [info->packetHandler release];
    [info->imageBufferUpdater release];
    info->packetHandler = nil;
    info->imageBufferUpdater = nil;
}


// ---------------------------------------------------------------------------------
//	Constants
// ---------------------------------------------------------------------------------
//	Defines various constants used throughout the plugin.

// ### GROUP ID
// Define the group under which this plugin will be displayed in the Isadora interface.
// These are defined under "Actor Types" in IsadoraTypes.h

static const OSType	kActorClass 	= kGroupVideo;

// ### PLUGIN IN
// Define the plugin's unique four character identifier. Contact TroikaTronix to
// obtain a unique four character code if you want to ensure that someone else
// has not developed a plugin with the same code. Note that TroikaTronix reserves
// all plugin codes that begin with an underline, an at-sign, and a pound sign
// (e.g., '_', '@', and '#'.)

static const OSType	kActorID		= FOUR_CHAR_CODE('BMCP');

// ### ACTOR NAME
// The name of the actor. This is the name that will be shown in the User Interface.

static const char* kActorName		= "iCapture";

// ### PROPERTY DEFINITION STRING
// The property string. This string determines the inputs and outputs for your plugin.
// See the IsadoraCallbacks.h under the heading "PROPERTY DEFINITION STRING" for the
// meaning ofthese codes. (The IsadoraCallbacks.h header can be seen by opening up
// the IzzySDK Framework while in the Files view.)
//
// IMPORTANT: You cannot use spaces in the property name. Instead, use underscores (_)
// where you want to have a space.
//
// Note that each line ends with a carriage return (\r), and that only the last line of
// the bunch ends with a semicolon. This means that what you see below is one long
// null-terminated c-string, with the individual lines separated by carriage returns.

static const char* sPropertyDefinitionString =

// INPUT PROPERTY DEFINITIONS
//	TYPE 	PROPERTY NAME	ID		DATATYPE	DISPLAY FMT			MIN		MAX		INIT VALUE
"INPROP     name            name	string      text				0		1		performer1\r"
"INPROP     port            port	int         number				0		10		0\r"
"INPROP     enabled         enbl	bool        onoff				0       1       0\r"

// OUTPUT PROPERTY DEFINITIONS
//	TYPE 	 PROPERTY NAME	ID		DATATYPE	DISPLAY FMT			MIN		MAX		INIT VALUE
"OUTPROP video_out          vout	data		video				*		*		0\r";

// ### Property Index Constants
// Properties are referenced by a one-based index. The first input property will
// be 1, the second 2, etc. Similarly, the first output property starts at 1.
// You whould have one constant for each input and output property defined in the
// property definition string.

enum
{
    kInputName = 1,
    kInputPort,
	kInputEnabled,
	
	kOutputVideo = 1
};


// ---------------------
//	Help String
// ---------------------
// ### Help Strings
//
// The first help string is for the actor in general. This followed by help strings
// for all of the inputs, and then by the help strings for all of the outputs. These
// should be given in the order that they are defined in the Property Definition
// String above.
//
// In all, the total number of help strings should be (num inputs + num outputs + 1)
//
// Note that each string is followed by a comma -- it is a common mistake to forget the
// comma which results in the two strings being concatenated into one.

const char* sHelpStrings[] =
{
	"A bonjour UDP service that can be sent video frames via the iCapture iOS App.",
    "The port number to use for this service.",
    
    "The name of the UDP bonjour service as it is seen by other applications.",
    
	"This enables or disabled the plugin.",
	
	"The video output."
};

// ---------------------------------------------------------------------------------
//		¥ CreateActor
// ---------------------------------------------------------------------------------
// Called once, prior to the first activation of an actor in its Scene. The
// corresponding DisposeActor actor function will not be called until the file
// owning this actor is closed, or the actor is destroyed as a result of being
// cut or deleted.


#define WIDTH 352
#define HEIGHT 288

static void
CreateActor(
            IsadoraParameters*	ip,
            ActorInfo*			ioActorInfo)		// pointer to this actor's ActorInfo struct - unique to each instance of an actor
{
	// creat the PluginInfo struct - initializing it to all zeroes
	PluginInfo* info = (PluginInfo*) IzzyMallocClear_(ip, sizeof(PluginInfo));
	PluginAssert_(ip, info != nil);
	
	ioActorInfo->mActorDataPtr = info;
	info->mActorInfoPtr = ioActorInfo;
    
	// ### allocation and initialization of private member variables
	
    
    // allocation and initialization of private member variables
	info->mImageOutputBufferPtr = ImageBuffer_MakeImageBuffer(WIDTH, HEIGHT, 32);
    ImageBuffer_InitImageBuffer(info->mImageOutputBufferPtr);
    ImageBuffer_CreateGWorld(info->mImageOutputBufferPtr, WIDTH, HEIGHT, 32);
    
    DEBUG_MESSAGE(@"createActor done\n")
}

// ---------------------------------------------------------------------------------
//		¥ DisposeActor
// ---------------------------------------------------------------------------------
// Called when the file owning this actor is closed, or when the actor is destroyed
// as a result of its being cut or deleted.
//
static void
DisposeActor(
             IsadoraParameters*	ip,
             ActorInfo*			ioActorInfo)		// pointer to this actor's ActorInfo struct - unique to each instance of an actor
{
	PluginInfo* info = GetPluginInfo_(ioActorInfo);
	PluginAssert_(ip, info != nil);
	
	// ### destruction of private member variables
	
	// destruction of private member variables
    ImageBuffer_DisposeGWorld(info->mImageOutputBufferPtr);
    ImageBuffer_DisposeImageBuffer(info->mImageOutputBufferPtr);
    
	// destroy the PluginInfo struct allocated with IzzyMallocClear_ the CreateActor function
	PluginAssert_(ip, ioActorInfo->mActorDataPtr != nil);
	IzzyFree_(ip, ioActorInfo->mActorDataPtr);
    
    disableNetworking(info);
    
    DEBUG_MESSAGE(@"disposeActor done\n")
}

// ---------------------------------------------------------------------------------
//		¥ ActivateActor
// ---------------------------------------------------------------------------------
//	Called when the scene that owns this actor is activated or deactivated. The
//	inActivate flag will be true when the scene is activated, false when deactivated.
//
static void
ActivateActor(
              IsadoraParameters*	ip,
              ActorInfo*			inActorInfo,		// pointer to this actor's ActorInfo struct - unique to each instance of an actor
              Boolean				inActivate)			// true when actor is becoming active, false otherwise.
{
	PluginInfo* info = GetPluginInfo_(inActorInfo);
	
	// ------------------------
	// ACTIVATE
	// ------------------------
    DEBUG_MESSAGE(@"ActivateActor called...\n")
	
	if (inActivate) {
        DEBUG_MESSAGE(@"\tactivating...\n")
        
		// Isadora passes various messages to plugins that request them.
		// These include Mouse Moved messages, Key Down/Key Up messages,
		// Video Frame Clock messages, etc. The complete list can be found
		// in the enumeration in MessageReceiverCommon.h
		
		// You ask Isadora¨ for these messages by calling CreateMessageReceiver_
		// with a pointer to your function, and the message types you would
		// like to receive. (These are bitmapped flags, so you can combine as
		// many as you like: kWantKeyDown | kWantKeyDown for instance.)
		
		// Here we request that our ReceiveMessage function is called
		// whenever the Isadora New Video Frame message is sent,
		// which happens periodically, 30 times per second. We set the ref
		// con to our ActorInfo ptr so that we can access that information
		// from ReceiveMessage callback.
		
		MessageReceiveFunction* msgRcvFunc = ReceiveMessage;
		
		// if enabled flag is on, then we want to receive messages
		if (info->mEnabled) {
            DEBUG_MESSAGE(@"\tenabled\n")
            
			// we should not already have a message receiver
			PluginAssert_(ip, info->mMessageReceiver == nil);
			
			// create a message receiver that will be notified of
			// video frame ticks
			info->mMessageReceiver = CreateMessageReceiver_(
                                                            ip,
                                                            msgRcvFunc,
                                                            0,
                                                            kWantVideoFrameTick,
                                                            (long) inActorInfo);
            
            enableNetworking(ip, info);
		} else {
            DEBUG_MESSAGE(@"\tdisabled\n")
            disableNetworking(info);
        }
		
		// set the needs draw flag so that we will be drawn as soon
		// as possible
		//info->mNeedsDraw = true;
        
        // ------------------------
        // DEACTIVATE
        // ------------------------
        
	} else {
        DEBUG_MESSAGE(@"\tdeactivating...\n")
        
		// dispose our message receiver when we are deactivated.
		if (info->mMessageReceiver != nil) {
			DisposeMessageReceiver_(ip, info->mMessageReceiver);
			info->mMessageReceiver = nil;
			info->mNeedsDraw |= true;
		}
		
        
        disableNetworking(info);
	}
    DEBUG_MESSAGE(@"ActivateActor done\n")
}

// ---------------------------------------------------------------------------------
//		¥ GetParameterString
// ---------------------------------------------------------------------------------
//	Returns the property definition string. Called when an instance of the actor
//	needs to be instantiated.

static const char*
GetParameterString(
                   IsadoraParameters*	/* ip */,
                   ActorInfo*			/* inActorInfo */)
{
	return sPropertyDefinitionString;
}

// ---------------------------------------------------------------------------------
//		¥ GetHelpString
// ---------------------------------------------------------------------------------
//	Returns the help string for a particular property. If you have a fixed number of
//	input and output properties, it is best to use the PropertyTypeAndIndexToHelpIndex_
//	function to determine the correct help string to return.

static void
GetHelpString(
              IsadoraParameters*	ip,
              ActorInfo*			inActorInfo,
              PropertyType		inPropertyType,			// kPropertyTypeInvalid when requesting help for the actor
              // or kInputProperty or kOutputProperty when requesting help for a specific property
              PropertyIndex		inPropertyIndex1,		// the one-based index of the property (when inPropertyType is not kPropertyTypeInvalid)
              char*				outParamaterString,		// receives the help string
              UInt32				inMaxCharacters)		// size of the outParamaterString buffer
{
	const char* helpstr = nil;
	
	// The PropertyTypeAndIndexToHelpIndex_ converts the inPropertyType and
	// inPropertyIndex1 parameters to determine the zero-based index into
	// your list of help strings.
	UInt32 index1 = PropertyTypeAndIndexToHelpIndex_(ip, inActorInfo, inPropertyType, inPropertyIndex1);
	
	// get the help string
	helpstr = sHelpStrings[index1];
	
	// copy it to the output string
	strncpy(outParamaterString, helpstr, inMaxCharacters);
}

// ---------------------------------------------------------------------------------
//		¥ HandlePropertyChangeValue	[INTERRUPT SAFE]
// ---------------------------------------------------------------------------------
//	### This function is called whenever one of the input values of an actor changes.
//	The one-based property index of the input is given by inPropertyIndex1.
//	The new value is given by inNewValue, the previous value by inOldValue.
//
static void
HandlePropertyChangeValue(
                          IsadoraParameters*	ip,
                          ActorInfo*			inActorInfo,
                          PropertyIndex		inPropertyIndex,			// the one-based index of the property than changed values
                          ValuePtr			/* inOldValue */,			// the property's old value
                          ValuePtr			inNewValue,					// the property's new value
                          Boolean				/* inInitializing */)		// true if the value is being set when an actor is first initalized
{
	PluginInfo* info = GetPluginInfo_(inActorInfo);
    
	// ### When you add/change/remove properties, you will need to add cases
	// to this switch statement, to process the messages for your
	// input properties
	
	// The value comes to you encapsulated in a Value structure. See
	// ValueCommon.h for details about the contents of this structure.
	
    DEBUG_MESSAGE(@"HandlePropertyChange called...\n")
    
	switch (inPropertyIndex) {
            
        case kInputName:
            info->mServiceName = inNewValue->u.str;
            DEBUG_MESSAGE(@"\tservice name set to: %s\n", info->mServiceName->strData)
            
            if (info->mEnabled) {
                disableNetworking(info);
                info->mEnabled = false;
                Value value = {kBoolean, 0};
                SetInputPropertyValue_(ip, inActorInfo, kInputEnabled, &value);
            }
            
            break;
            
        case kInputPort:
            info->mPort = inNewValue->u.ivalue;
            DEBUG_MESSAGE(@"\tservice name set to: %s\n", info->mServiceName->strData)
            
            if (info->mEnabled) {
                disableNetworking(info);
                info->mEnabled = false;
                Value value = {kBoolean, 0};
                SetInputPropertyValue_(ip, inActorInfo, kInputEnabled, &value);
            }

            break;
            
            // When the enabled input property is set to 1 (on) this
            // actor processes UDP packets.
        case kInputEnabled:
            // store member variable for on/off
            DEBUG_MESSAGE(@"\tenabled set to: %s\n", (inNewValue->u.ivalue == 0 ? "no" : "yes"))
            info->mEnabled = (inNewValue->u.ivalue != 0);
            
            if (info->mEnabled) {
                if (info->mMessageReceiver == nil) {
                    info->mMessageReceiver = CreateActorMessageReceiver_(
                                                                         ip,
                                                                         inActorInfo,
                                                                         ReceiveMessage,
                                                                         0,
                                                                         kWantVideoFrameTick,
                                                                         (long) inActorInfo);
                }
                
                enableNetworking(ip, info);
                
            } else {
                if (info->mMessageReceiver != nil) {
                    DisposeMessageReceiver_(ip, info->mMessageReceiver);
                    info->mMessageReceiver = nil;
                    info->mNeedsDraw |= true;
                }
                
                disableNetworking(info);
            }
            break;
	}
    DEBUG_MESSAGE(@"HandlePropertyChange done\n")
}

// ---------------------------------------------------------------------------------
//		¥ GetActorDefinedArea
// ---------------------------------------------------------------------------------
//	If the mGetActorDefinedAreaProc in the ActorInfo struct points to this function,
//	it indicates to Isadora that the object would like to draw either an icon or else
//	an graphic representation of its function.
//
//	### This function uses the 'PICT' 0 resource stored with the plugin to draw an icon.
//  You should replace this picture (located in the Plugin Resources.rsrc file) with
//  the icon for your actor.
//
static ActorPictInfo	gPictInfo = { false, nil, nil, 0, 0 };

static Boolean
GetActorDefinedArea(
                    IsadoraParameters*			ip,
                    ActorInfo*					inActorInfo,
                    SInt16*						outTopAreaWidth,			// returns the width to reserve for the top Actor Defined Area
                    SInt16*						outTopAreaMinHeight,		// returns the minimum height of the top area
                    SInt16*						outBotAreaHeight,			// returns the width to reserve for the bottom Actor Defined Area
                    SInt16*						outBotAreaMinWidth)			// returns the minimum width of the bottom area
{
	if (gPictInfo.mInitialized == false) {
		PrepareActorDefinedAreaPict_(ip, inActorInfo, 0, &gPictInfo);
	}
	
	// place picture in top area
	*outTopAreaWidth = gPictInfo.mWidth;
	*outTopAreaMinHeight = gPictInfo.mHeight;
	
	// don't draw anything in bottom area
	*outBotAreaHeight = 0;
	*outBotAreaMinWidth = 0;
	
	return true;
}

// ---------------------------------------------------------------------------------
//		¥ DrawActorDefinedArea
// ---------------------------------------------------------------------------------
//	If GetActorDefinedArea is defined, then this function will be called whenever
//	your ActorDefinedArea needs to be drawn.
//
//	Beacuse we are using the PICT 0 resource stored with this plugin, we can use
//	the DrawActorDefinedAreaPict_ supplied by the Isadora callbacks.
//
//  DrawActorDefinedAreaPict_ is Alpha Channel aware, so you can have nice
//	shading if you like.

static void
DrawActorDefinedArea(
                     IsadoraParameters*			ip,
                     ActorInfo*					inActorInfo,
                     void*						/* inDrawingContext */,		// unused at present
                     ActorDefinedAreaPart		inActorDefinedAreaPart,		// the part of the actor that needs to be drawn
                     ActorAreaDrawFlagsT			/* inAreaDrawFlags */,		// actor draw flags
                     Rect*						inADAArea,					// rect enclosing the entire Actor Defined Area
                     Rect*						/* inUpdateArea */,			// subset of inADAArea that needs updating
                     Boolean						inSelected)					// TRUE if actor is currently selected
{
	if (inActorDefinedAreaPart == kActorDefinedAreaTop
        && gPictInfo.mInitialized == true) {
		DrawActorDefinedAreaPict_(ip, inActorInfo, inSelected, inADAArea, &gPictInfo);
	}
}

// ---------------------------------------------------------------------------------
//		¥ GetActorInfo
// ---------------------------------------------------------------------------------
//	This is function is called by to get the actor's class and ID, and to get
//	pointers to the all of the plugin functions declared locally.
//
//	All members of the ActorInfo struct pointed to by outActorParams have been
//	set to 0 on entry. You only need set functions defined by your plugin
//
EXPORT_ void
GetActorInfo(
             void*				/* inParam */,
             ActorInfo*			outActorParams)
{
	// REQUIRED information
	outActorParams->mActorName							= kActorName;
	outActorParams->mClass								= kActorClass;
	outActorParams->mID									= kActorID;
	outActorParams->mCompatibleWithVersion				= kCurrentIsadoraCallbackVersion;
	
	// REQUIRED functions
	outActorParams->mGetActorParameterStringProc		= GetParameterString;
	outActorParams->mGetActorHelpStringProc				= GetHelpString;
	outActorParams->mCreateActorProc					= CreateActor;
	outActorParams->mDisposeActorProc					= DisposeActor;
	outActorParams->mActivateActorProc					= ActivateActor;
	outActorParams->mHandlePropertyChangeValueProc		= HandlePropertyChangeValue;
	
	// OPTIONAL FUNCTIONS
	outActorParams->mHandlePropertyChangeTypeProc		= NULL;
	outActorParams->mHandlePropertyConnectProc			= NULL;
	outActorParams->mPropertyValueToStringProc			= NULL;
	outActorParams->mPropertyStringToValueProc			= NULL;
	outActorParams->mGetActorDefinedAreaProc			= GetActorDefinedArea;
	outActorParams->mDrawActorDefinedAreaProc			= DrawActorDefinedArea;
	outActorParams->mMouseTrackInActorDefinedAreaProc	= NULL;
}

// ---------------------------------------------------------------------------------
//		¥ ReceiveMessage
// ---------------------------------------------------------------------------------
//	Isadora broadcasts messages to its Message Receives depending on what message
//	they are listening to. In this case, we are listening for kWantVideoFrameTick,
//	which is broadcast periodically (30 times per second.) When we receive the
//	message, we check to see if our video frame needs to be updated. If so, we
//	process the incoming video and pass the newly generated frame to the output.

static void
ReceiveMessage(
               IsadoraParameters*	ip,
               MessageMask			/* inMessageMask */,		// the message that caused this ReceiveMessage to be called -- one of the kWant... constants
               PortIndex			/* inIndex1 */,				// for MIDI messages, the port from which the message arrived. n/a otherwise
               const MsgData*		/* inData */,				// the data associated with this message
               UInt32				/* inLen */,				// the length of the data associated with this message
               long				inRefCon)					// in our use, actually the pointer to our ActorInfo
{
	// Convert the refCon into the ActorInfo* that it
	// really is, so that we can get at our data
	ActorInfo* actorInfo = reinterpret_cast<ActorInfo*>(inRefCon);
    
	// get pointer to plugin info
	PluginInfo* info = GetPluginInfo_(actorInfo);
    
    // the return value for the output property
    Value v = { kData, nil };
    
    if (info->mEnabled) {
        
        @synchronized (info->imageBufferUpdater) {
            if (info->mNeedsDraw) {
                
                info->mNeedsDraw = false; // reset - this gets set true by the connectionHandler
                UInt64 vpStart = EnterVideoProcessing_(ip);
                
                ImageBuffer_IncrementFrameCount(info->mImageOutputBufferPtr);
                
                v.u.data = info->mImageOutputBufferPtr;
                
                // send the new video frame to the video output property
                SetOutputPropertyValue_(ip, info->mActorInfoPtr, kOutputVideo, &v);
                
                ExitVideoProcessing_(ip, vpStart);
            }
        }
    } else {
        v.u.data = nil;
        SetOutputPropertyValue_(ip, info->mActorInfoPtr, kOutputVideo, &v);
    }
}
