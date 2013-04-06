//
//  Light.m
//  ios3D
//
//  Created by Alun on 4/5/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Light.h"

@implementation Light
@synthesize direction, intensity, diffuseColor, ambientColor, specularColor;

- (id)initWitName:(NSString*)name {
    if ((self = [super init])) {
        self.diffuseColor = GLKVector3Make(1.0, 1.0, 1.0);
    }
    return self;
}

@end
