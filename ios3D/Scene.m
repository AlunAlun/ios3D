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

- (id)initWithProgram:(GLuint)program error:(NSError**)error{
    if ((self = [super init])) {
        _program = program;

        /*
        WaveFrontObject *currOBJ = [self addChildOBJ:@"avatar_girl.obj" error:error];
        if (!currOBJ ) return nil;
         */
 
        WaveFrontObject *currOBJ = [self addChildOBJ:@"skirt.obj" error:error];
        if (!currOBJ ) return nil;
        Material *m = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg"];
        currOBJ.materialDefault = m;

        
        currOBJ = [self addChildOBJ:@"tshirt.obj" error:error];
        if (!currOBJ ) return nil;
        m = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg"];
        currOBJ.materialDefault = m;
        
        currOBJ = [self addChildOBJ:@"floor.obj" error:error];
        if (!currOBJ ) return nil;

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

-(WaveFrontObject*)addChildOBJ:(NSString*)fileName error:(NSError**)error
{
    NSString *baseName = [[fileName componentsSeparatedByString:@"."] objectAtIndex:0];
    NSString *fileType = [[fileName componentsSeparatedByString:@"."] objectAtIndex:1];
    NSString *path = [[NSBundle mainBundle] pathForResource:baseName ofType:fileType];
    NSMutableDictionary* details = [NSMutableDictionary dictionary];
    if (path == nil)
    {
        [details setValue:[NSString stringWithFormat:@"Couldn't find file %@",fileName] forKey:NSLocalizedDescriptionKey] ;
        *error = [NSError errorWithDomain:@"OBJ" code:001 userInfo:details];
        return nil;
    }
    
    WaveFrontObject *theObject = [[WaveFrontObject alloc] initWithPath:path program:_program error:error];

    if (!theObject) {
        // inspect error
        //NSLog(@"%@", [errorr localizedDescription]);
        return false;
    }
    else [self addChild:theObject];
    return theObject;

}

@end
