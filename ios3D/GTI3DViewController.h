//
//  GTI3DViewController.h
//  ios3D
//
//  Created by Alun on 3/26/13.
//  Copyright (c) 2013 GTI. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ControlPanel.h"



@interface GTI3DViewController : GLKViewController <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *performanceLabel;

@property (weak, nonatomic) IBOutlet ControlPanel *controlPanel;
@end
