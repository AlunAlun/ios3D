//
//  ControlPanel.h
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Node.h"

@interface ControlPanel : UIView

@property (nonatomic, weak) IBOutlet UIView *sceneTree;
@property (nonatomic, strong) NSMutableArray *nodeNames;
@property (assign) int currentNode;

-(void)drawTree;
-(void)addNodeName:(NSString *)newName;


@end
