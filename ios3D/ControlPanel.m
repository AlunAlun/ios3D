//
//  ControlPanel.m
//  ios3D
//
//  Created by Alun on 4/1/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import "ControlPanel.h"
#import "Scene.h"
#import "AssetsSingleton.h"

@implementation ControlPanel
@synthesize sceneTree = _sceneTree;
@synthesize nodeNames = _nodeNames;
@synthesize currentNode = _currentNode;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.currentNode = 0;

    }
    return self;
}

-(void)addNodeName:(NSString*)newName{
    
    if (self.nodeNames == nil) self.nodeNames = [[NSMutableArray alloc] init];
    [self.nodeNames addObject:newName];
}

-(void)drawTree
{
    //**************************************
    // NODE SELECT
    //**************************************
    
    //title
    UILabel *treeTitle = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 10.0, 300.0, 20.0)];
    treeTitle.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:0.16];
    treeTitle.textColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    treeTitle.text = @"Nodes";
    [self addSubview:treeTitle];
    
    //make frame for tree
    UIView *treeView = [[UIView alloc] initWithFrame:CGRectMake(10.0, 35.0, 280.0, 200.0)];
    treeView.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:1.0];
    [self addSubview:treeView];
    
    //add labels for all nodes
    float yIncrement = 10.0;
    for(Node* node in [AssetsSingleton sharedAssets].scene.children)
    {
        UILabel *newLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, yIncrement, 260.0, 20.0)];
        yIncrement+=25;
        newLabel.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:0.16];
        newLabel.textColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
        newLabel.text = [NSString stringWithFormat:@"- %@", node.name];
        //newLabel.tag =
        [treeView addSubview:newLabel];
    }

    
    //**************************************
    // Materials section
    //**************************************
    
    //title
    UILabel *materialTitle = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 260.0, 300.0, 20)];
    materialTitle.backgroundColor = [UIColor colorWithRed:0.16 green:0.16 blue:0.16 alpha:0.16];
    materialTitle.textColor = [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:1.0];
    materialTitle.text = @"Material";
    [self addSubview:materialTitle];
    
    //get material of current node
    Node *currNodeObject = [[AssetsSingleton sharedAssets].scene.children objectAtIndex:self.currentNode];
    Material *mat = currNodeObject.materialDefault;
    
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/


@end
