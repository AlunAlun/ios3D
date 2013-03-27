//
//  Material.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface Material : NSObject

@property(strong) GLKTextureInfo *texture;

-(id)initWithTexture:(NSString*)filename ofType:(NSString*)type;

@end
