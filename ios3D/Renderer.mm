//
//  Renderer.m
//  ios3D
//
//  Created by Alun on 4/6/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "Renderer.h"

@implementation Renderer



static Renderer *renderSingleton = nil;    // static instance variable

+ (Renderer *)renderer {
    if (renderSingleton == nil) {
        renderSingleton = [[super allocWithZone:NULL] init];
    }
    return renderSingleton;
}

- (id)init {
    if ( (self = [super init]) ) {

    }
    return self;
}

@end
