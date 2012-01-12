//
//  DataManagerAppDelegate.h
//  DataManager
//
//  Created by wang  chao on 12-1-12.
//  Copyright 2012年 bupt. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataManagerViewController;

@interface DataManagerAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet DataManagerViewController *viewController;

@end
