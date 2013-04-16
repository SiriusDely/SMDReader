//
//  SMDAppDelegate.m
//  SMDReader
//
//  Created by SiriusDely on 4/5/13.
//  Copyright (c) 2013 SiriusDely. All rights reserved.
//

#import "SMDAppDelegate.h"
#import "EPubViewController.h"

@implementation SMDAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  NSURL *fileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"vhugo" ofType:@"epub"]];
  EPubViewController *pubViewController = [[EPubViewController alloc] initWithFilePath:fileUrl.path];
  [self.window setRootViewController:pubViewController];
  [self.window makeKeyAndVisible];
  return YES;
}

@end
