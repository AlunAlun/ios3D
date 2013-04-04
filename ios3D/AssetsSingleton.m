//
//  AssetsSingleton.m
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "AssetsSingleton.h"

@implementation AssetsSingleton
@synthesize scene, materials, textures, totalTris, sceneNodes, context;

static AssetsSingleton *sharedAssetsSingleton = nil;    // static instance variable

+ (AssetsSingleton *)sharedAssets {
    if (sharedAssetsSingleton == nil) {
        sharedAssetsSingleton = [[super allocWithZone:NULL] init];
    }
    return sharedAssetsSingleton;
}

- (id)init {
    if ( (self = [super init]) ) {
        // your custom initialization
        self.materials = [[NSMutableArray alloc] init];
        self.textures = [[NSMutableArray alloc] init];
        self.sceneNodes = [[NSMutableArray alloc] init];
        totalTris = 0;
    }
    return self;
}

- (void)addSceneNode:(Node *)node{
    [self.sceneNodes addObject:node];
}
-(Node*)getSceneNodeWithName:(NSString *)name
{
    for(Node *n in self.sceneNodes)
        if (n.name == name) return n;
    return nil;
}
@end