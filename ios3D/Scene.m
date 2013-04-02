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
#import "GTI3DViewController.h"

@interface Scene ()
{
    GLuint _program;
}

@property(nonatomic, strong) NSMutableArray *textures;
@property(nonatomic, strong) NSMutableArray *materials;
@property(nonatomic, strong) NSMutableArray *objects;

@end

@implementation Scene
@synthesize textures;

- (id)initWithProgram:(GLuint)program error:(NSError**)error{
    if ((self = [super init])) {
        _program = program;

        
        WaveFrontObject *avatarOBJ = [self addChildOBJ:@"avatar_girl.obj" error:error];
        if (!avatarOBJ ) return nil;
        avatarOBJ.name = @"Avatar";
        Material *avatarMat = [[Material alloc] init];
        avatarOBJ.materialDefault = avatarMat;
        
        WaveFrontObject *skirtOBJ = [self addChildOBJ:@"skirt.obj" error:error];
        if (!skirtOBJ ) return nil;
        skirtOBJ.name = @"Skirt";
        Material *m = [[Material alloc] initWithTexture:@"dress_skirt" ofType:@"jpg"];
        skirtOBJ.materialDefault = m;
        [m loadDetailTexture:@"detail_jeans" ofType:@"png"];
        
        
        WaveFrontObject *shirtOBJ = [self addChildOBJ:@"tshirt.obj" error:error];
        if (!shirtOBJ ) return nil;
        shirtOBJ.name = @"Shirt";
        m = [[Material alloc] initWithTexture:@"dress_top" ofType:@"jpg"];
        shirtOBJ.materialDefault = m;
        
        
        WaveFrontObject *floorOBJ = [self addChildOBJ:@"floor.obj" error:error];
        if (!floorOBJ ) return nil;
        floorOBJ.name = @"Floor";
        Material *floorMat = [[Material alloc] init];
        floorMat.ambient = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
        [floorMat loadDetailTexture:@"white" ofType:@"png"];
        floorOBJ.materialDefault = floorMat;
         
       
        /*SimpleCube *cube = [[SimpleCube alloc] initWithProgram:program];
        cube.name = @"cube";
        cube.scale = 300.0f;
        [self addChild:cube];
         */
        

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
