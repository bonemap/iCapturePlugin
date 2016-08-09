//
//  ImageBufferUpdater.m
//  NerveCenterPlugin
//
//  Created by Residue on 23/11/12.
//
//

#import "ImageBufferUpdater.h"
#import <AppKit/AppKit.h>
#include "VidColorMacros.h"

@implementation ImageBufferUpdater

- (id) initWithIsadoraParameters: (IsadoraParameters*) params
                      pluginInfo: (PluginInfo*) info {
    
    
    if ((self = [super init]) != nil) {
        _params = params;
        _info = info;
    }
    
    return self;
    
}

typedef struct  { UInt8 a, b, c, d; } Pixel;

- (void)receivedFrame:(NSData *)data {
    
    //    [data retain];
    //    [[SharedFileLogger new] addMessage:@"\treceivedFrame triggered\n"];
    
    @synchronized (self) {
        NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithData:data];
        
        Pixel* pixels = (Pixel*)imageRep.bitmapData;
        
        //	ImageBufferPtr imageBuffer = GetImageBufferPtr(_params, &_info->mImageBufferMap, 0);
        //    ImageBufferPtr imageBuffer = GetOutputImageBufferPtr(&_info->mImageBufferMap, 0);
        ImageBufferPtr imageBuffer = _info->mImageOutputBufferPtr;
        
        UInt32* bufferData = static_cast<UInt32*>(imageBuffer->mBaseAddress);
        UInt32 bufferStride = imageBuffer->mRowBytes - imageBuffer->mWidth * sizeof(UInt32);
        
        // for each row
        SInt16 row = 0;
        while (row < imageBuffer->mHeight) {
            
            // and for each column in that row
            SInt16 col = 0;
            while (col < imageBuffer->mWidth) {
                
                Pixel pixel = pixels[col + row * imageBuffer->mWidth];
                *(bufferData) = ARGB_(pixel.c, pixel.b, pixel.a, pixel.d);
                
                ++bufferData;
                
                // increment col count
                ++col;
                
            }
            // skip to the next line of video, using the
            // stride values computed above
            bufferData = (UInt32*)((char*) bufferData + bufferStride);
            
            // increment row count
            ++row;
            
        }
        
        //    [[SharedFileLogger new] addMessage:@"\tisadora image buffer updated\n"];
        //
        //    [[SharedFileLogger new] addMessage:@"\treceivedFrame done\n"];
        
        _info->mNeedsDraw = true;
        //    [imageRep release];
        
        //    [data release];
    }
    
}

@end
