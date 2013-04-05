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

- (id)initWitName:(NSString*)name;
- (Camera*)getCamera:(int)camId;
- (Light*)getLight:(int)lightId;
@end
