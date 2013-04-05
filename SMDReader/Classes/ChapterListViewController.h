//
//  ChapterListViewController.h
//  AePubReader
//
//  Created by Federico Frappi on 04/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPubViewController.h"

@interface ChapterListViewController : UITableViewController

@property(nonatomic, strong) EPubViewController *epubViewController;

@end
