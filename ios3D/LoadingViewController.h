//
//  LoadingViewController.h
//  ios3D
//
//  Created by Alun on 4/3/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "JSONLoaders.h"

@interface LoadingViewController : UIViewController
@property (nonatomic, strong) NSString *serverAssetPath;
@property (nonatomic, strong) JSONScene *jsonScene;
@end
