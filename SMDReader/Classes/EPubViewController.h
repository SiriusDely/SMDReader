//
//  DetailViewController.h
//  AePubReader
//
//  Created by Federico Frappi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ZipArchive.h>
#import "EPub.h"
#import "Chapter.h"

@class SearchResultsViewController;
@class SearchResult;

@interface EPubViewController : UIViewController

@property (nonatomic, strong) EPub *epub;
@property (nonatomic, assign) BOOL searching;

- (id)initWithFilePath:(NSString *)path;
- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult *)result;

@end
