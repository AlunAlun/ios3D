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


@property(nonatomic, strong) NSMutableArray *textures;
@property(nonatomic, strong) NSMutableArray *materials;
@property(nonatomic, strong) NSMutableArray *objects;


@end

@implementation Scene
@synthesize textures, materials, objects, backgroundColor, lightMoved, camMoved;

- (id)initWitName:(NSString*)name {
    if ((self = [super init])) {
        self.name = name;
        backgroundColor = GLKVector3Make(1.0, 1.0, 1.0);
        self.ambient = GLKVector3Make(1.0, 1.0, 1.0);
        lightMoved = true;
        camMoved = true;
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

-(Node*)getChild:(NSString *)name
{

    for (Node *n in self.children)
    {
        if (n.name == name)
            return (Node*)n;
    }
    return nil;
}

-(Camera*)getCamera:(int)camId
{
    int counter = 0;
    for (Node *n in self.children)
    {
        if ([n isKindOfClass:[Camera class]])
        {
            if(counter==camId)
                return (Camera*)n;
            else
                counter++;
        }
        
    }
    return nil;
}

-(Light*)getLight:(int)lightId
{
    int counter = 0;
    for (Node *n in self.children)
    {
        if ([n isKindOfClass:[Light class]])
        {
            if(counter==lightId)
                return (Light*)n;
            else
                counter++;
        }
        
    }
    return nil;
}

- (int)getNumLights
{
    int counter = 0;
    for (Node *n in self.children)
    {
        if ([n isKindOfClass:[Light class]])
            counter++;
    }
    return counter;
}

- (int)getNumCameras
{
    int counter = 0;
    for (Node *n in self.children)
    {
        if ([n isKindOfClass:[Camera class]])
            counter++;
    }
    return counter;
}

@end
