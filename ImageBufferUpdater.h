//
//  ImageBufferUpdater.h
//  NerveCenterPlugin
//
//  Created by Residue on 23/11/12.
//
//

#import <Foundation/Foundation.h>
#import "DataFrameBuffer.h"

#include "IsadoraTypes.h"
#include "IsadoraCallbacks.h"
#import "PluginInfo.h"

@interface ImageBufferUpdater : NSObject
<DataFrameBufferDelegate> {
    PluginInfo* _info;
    IsadoraParameters* _params;
}


- (id) initWithIsadoraParameters: (IsadoraParameters*) params
                      pluginInfo: (PluginInfo*) info;

@end
