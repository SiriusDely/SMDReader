//
//  SearchResultsViewController.h
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPubViewController.h"

@interface SearchResultsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate>

@property (nonatomic, strong) UITableView *resultsTableView;
@property (nonatomic, strong) EPubViewController *epubViewController;
@property (nonatomic, strong) NSMutableArray *results;
@property (nonatomic, strong) NSString *currentQuery;
@property (nonatomic, assign) int currentChapterIndex;

- (void)searchString:(NSString *)query;

@end
