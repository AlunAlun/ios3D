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
@synthesize textures;

- (id)initWitName:(NSString*)name {
    if ((self = [super init])) {
        self.name = name;
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
