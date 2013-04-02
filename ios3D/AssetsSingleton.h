//
//  AssetsSingleton.h
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Scene.h"

@interface AssetsSingleton : NSObject {
    // whatever instance vars you want
}

@property (nonatomic, strong) Scene *scene;
@property (nonatomic, strong) NSMutableArray *textures;
@property (nonatomic, strong) NSMutableArray *materials;
@property (assign) int totalTris;

+ (AssetsSingleton *)sharedAssets;   // class method to return the singleton object

- (void)customMethod; // add optional methods to customize the singleton class

@end
