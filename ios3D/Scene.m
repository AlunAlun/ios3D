//
//  Scene.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Scene.h"

@implementation Scene

- (id)init {
    if ((self = [super init])) {
        //TODO: add children
    }
    return self;
}

//update childred
-(void)update:(float)dt{
    
    //TODO: do any global scene rotations or anything
    
    
    //update all children
    for (Node * node in self.children) {
        [node update:dt];
    }
    
    
}


@end
