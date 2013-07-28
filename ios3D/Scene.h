//
//  Scene.h
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Node.h"
#import "Camera.h"
#import "Light.h"

@interface Scene : Node

@property(assign) GLKVector3 backgroundColor;
@property(nonatomic, assign) GLKVector3 ambient;
@property(assign) bool camMoved;
@property(assign) bool lightMoved;

- (id)initWitName:(NSString*)name;
- (Camera*)getCamera:(int)camId;
- (Light*)getLight:(int)lightId;
- (int)getNumLights;
- (Node*)getChild:(NSString *)name;
- (int)getNumCameras;
@end
