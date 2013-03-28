//
//  Scene.m
//  ios3D
//
//  Created by Alun on 3/27/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Scene.h"
#import "SimpleCube.h"
#import "Material.h"
#import "WaveFrontObject.h"

@interface Scene ()
{
    GLuint _program;
}

@end

@implementation Scene

- (id)initWithProgram:(GLuint)program {
    if ((self = [super init])) {
        _program = program;

        Material *mat = [[Material alloc] initWithTexture:@"SquareTexture" ofType:@"pvr"];
        
        for (int x = -2; x < 2; x++)
        {
            for (int z = -2; z < 2; z++)
            {
                SimpleCube *cube = [[SimpleCube alloc] initWithMaterial:mat program:_program];
                cube.position = GLKVector3Make(x, 0, z);
                cube.scale = 0.5;
                
                //[self addChild:cube];
            }
        }

        SimpleCube *cube = [[SimpleCube alloc] initWithMaterial:mat program:_program];
       // [self addChild:cube];
        
        NSString *path = [[NSBundle mainBundle] pathForResource:@"uvcube2" ofType:@"obj"];
        WaveFrontObject *theObject = [[WaveFrontObject alloc] initWithPath:path program:_program];
        [self addChild:theObject];
        

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
