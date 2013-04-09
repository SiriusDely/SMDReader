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

@interface EPubViewController : UIViewController <UIWebViewDelegate, ChapterDelegate, UISearchBarDelegate>

- (id)initWithUrl:(NSURL *)url;

- (IBAction)showChapterIndex:(id)sender;
- (IBAction)increaseTextSizeClicked:(id)sender;
- (IBAction)decreaseTextSizeClicked:(id)sender;
- (IBAction)slidingStarted:(id)sender;
- (IBAction)slidingEnded:(id)sender;
- (IBAction)doneClicked:(id)sender;

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult *)theResult;
- (void)loadEpub:(NSURL *)epubURL;

@property (nonatomic, strong) EPub *loadedEpub;
@property (nonatomic, strong) SearchResult *currentSearchResult;
@property (nonatomic, strong) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *chapterListButton, *decTextSizeButton, *incTextSizeButton;
@property (nonatomic, strong) IBOutlet UISlider *pageSlider;
@property (nonatomic, strong) IBOutlet UILabel *currentPageLabel;
@property (nonatomic, strong) UIPopoverController *chaptersPopover, *searchResultsPopover;
@property (nonatomic, strong) SearchResultsViewController *searchResViewController;
@property (nonatomic, assign) int currentSpineIndex, currentPageInSpineIndex, pagesInCurrentSpineCount, currentTextSize, totalPagesCount;
@property (nonatomic, assign) BOOL epubLoaded, paginating, searching;
@property (nonatomic, strong) NSURL *url;

@end
