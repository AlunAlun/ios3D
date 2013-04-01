//
//  AssetsSingleton.m
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "AssetsSingleton.h"

@implementation AssetsSingleton
@synthesize scene, materials, textures;

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
    }
    return self;
}

- (void)customMethod {
    // implement your custom code here
}
@end