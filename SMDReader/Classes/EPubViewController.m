//
//  DetailViewController.m
//  AePubReader
//
//  Created by Federico Frappi on 04/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EPubViewController.h"
#import "ChapterListViewController.h"
#import "SearchResultsViewController.h"
#import "SearchResult.h"
#import "UIWebView+SearchWebView.h"
#import "Chapter.h"

@interface EPubViewController ()
@property (nonatomic, strong) NSURL *url;
- (void)gotoNextSpine;
- (void)gotoPrevSpine;
- (void)toggleToolbar;
- (void)gotoNextPage;
- (void)gotoPrevPage;
- (int)getGlobalPageCount;
- (void)gotoPageInCurrentSpine:(int)pageIndex;
- (void)updatePagination;
- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex;
- (void)load;
@end

@implementation EPubViewController

@synthesize loadedEpub = _loadedEpub, toolbar = _toolbar, webView = _webView;
@synthesize chapterListButton = _chapterListButton, decTextSizeButton = _decTextSizeButton, incTextSizeButton = _incTextSizeButton;
@synthesize currentPageLabel = _currentPageLabel, pageSlider = _pageSlider;
@synthesize currentSearchResult = _currentSearchResult;
@synthesize chaptersPopover = _chaptersPopover, searchResultsPopover = _searchResultsPopover;
@synthesize searchResViewController = _searchResViewController;
@synthesize currentSpineIndex = _currentSpineIndex, currentPageInSpineIndex = _currentPageInSpineIndex, pagesInCurrentSpineCount = _pagesInCurrentSpineCount,
currentTextSize = _currentTextSize, totalPagesCount = _totalPagesCount;
@synthesize epubLoaded = _epubLoaded, paginating = _paginating, searching = _searching, url = _url;

- (id)initWithUrl:(NSURL *)url {
  if (self = [super init]) {
    _url = url;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  [self.view setBackgroundColor:[UIColor whiteColor]];
  //_webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x+2.0, self.view.bounds.origin.y+2.0, self.view.bounds.size.width-(2*2.0), self.view.bounds.size.height-(2*2.0))];
  _webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x+20.0, self.view.bounds.origin.y+44.0+20.0, self.view.bounds.size.width-(2*20.0), 862.0)];
  [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  [_webView setContentMode:UIViewContentModeScaleToFill];
  [self.view addSubview:_webView];
  _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, 44.0)];
  [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
  [_toolbar setAlpha:0.7];
  UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleBordered
                                                                        target:self action:@selector(doneClicked:)];
  UIBarButtonItem *flexibleBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [_toolbar setItems:[NSArray arrayWithObjects:closeBarButtonItem, flexibleBarButtonItem, nil]];
  [self.view addSubview:_toolbar];
  _pageSlider = [[UISlider alloc] initWithFrame:CGRectMake(_webView.frame.origin.x-(4.0/2), self.view.bounds.origin.y+self.view.bounds.size.height-20.0-23.0, _webView.frame.size.width+4.0, 23.0)];
  [_pageSlider setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
  [_pageSlider setMinimumValue:0.0];
  [_pageSlider setMaximumValue:100.0];
  [_pageSlider addTarget:self action:@selector(slidingStarted:) forControlEvents:UIControlEventValueChanged];
  [_pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpInside];
  [_pageSlider addTarget:self action:@selector(slidingEnded:) forControlEvents:UIControlEventTouchUpOutside];
  [self.view addSubview:_pageSlider];
	[_pageSlider setThumbImage:[UIImage imageNamed:@"slide-center"] forState:UIControlStateNormal];
	[_pageSlider setMinimumTrackImage:[[UIImage imageNamed:@"slide-normal"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
	[_pageSlider setMaximumTrackImage:[[UIImage imageNamed:@"slide-highlighted"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
  [_pageSlider setAlpha:0.7];
  _currentPageLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x+(self.view.bounds.size.width-100.0)/2, _pageSlider.frame.origin.y-21.0, 100.0, 21.0)];
  [_currentPageLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin];
  [_currentPageLabel setBackgroundColor:[UIColor clearColor]];
  [_currentPageLabel setTextAlignment:NSTextAlignmentCenter];
  [_currentPageLabel setFont:[UIFont fontWithName:@"Helvetica" size:17.0]];
  [_currentPageLabel setText:@"0/0"];
  [_currentPageLabel setAlpha:0.7];
  [self.view addSubview:_currentPageLabel];
}

#pragma mark - View Lifecycles

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  NSLog(@"viewDidLoad");
  [super viewDidLoad];
  //return;
	[_webView setDelegate:self];
	UIScrollView *sv = nil;
	for (UIView *v in  _webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView *)v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
	_currentTextSize = 100;
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbar)];
	UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoNextPage)];
	[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
	UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPrevPage)];
	[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	[self.view addGestureRecognizer:tapRecognizer];
	[_webView addGestureRecognizer:rightSwipeRecognizer];
	[_webView addGestureRecognizer:leftSwipeRecognizer];
	_searchResViewController = [[SearchResultsViewController alloc] init];
	[_searchResViewController setEpubViewController:self];
  [self load];
}

- (void)viewDidUnload {
	self.toolbar = nil;
	self.webView = nil;
	self.chapterListButton = nil;
	self.decTextSizeButton = nil;
	self.incTextSizeButton = nil;
	self.pageSlider = nil;
	self.currentPageLabel = nil;
}

#pragma mark - Rotation support

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"shouldAutorotateToInterfaceOrientation:");
  [self updatePagination];
	return YES;
}

#pragma mark - Private Methods

- (void)load {
  _currentSpineIndex = 0;
  _currentPageInSpineIndex = 0;
  _pagesInCurrentSpineCount = 0;
  _totalPagesCount = 0;
	_searching = NO;
  _epubLoaded = NO;
  self.loadedEpub = [[EPub alloc] initWithUrl:self.url];
  _epubLoaded = YES;
  NSLog(@"loadEpub");
	[self updatePagination];
}

- (void)toggleToolbar {
  NSLog(@"toggleToolbar");
  [UIView animateWithDuration:0.7f animations:^ {
    if (_toolbar.hidden) {
      [_toolbar setAlpha:0.7];
      [_currentPageLabel setAlpha:0.7];
      [_pageSlider setAlpha:0.7];
    } else {
      [_toolbar setAlpha:0.0];
      [_currentPageLabel setAlpha:0.0];
      [_pageSlider setAlpha:0.0];
    }
  } completion:^(BOOL finished) {
    [_toolbar setHidden:!_toolbar.hidden];
    [_currentPageLabel setHidden:!_currentPageLabel.hidden];
    [_pageSlider setHidden:!_pageSlider.hidden];
  }];
}

- (void)gotoNextPage {
	if (!_paginating) {
		if (_currentPageInSpineIndex+1 < _pagesInCurrentSpineCount) {
			[self gotoPageInCurrentSpine:++_currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}
	}
}

- (void)gotoPrevPage {
	if (!_paginating) {
		if (_currentPageInSpineIndex-1 >= 0) {
			[self gotoPageInCurrentSpine:--_currentPageInSpineIndex];
		} else {
			if (_currentSpineIndex != 0) {
				int targetPage = [[_loadedEpub.spineArray objectAtIndex:(_currentSpineIndex-1)] pageCount];
				[self loadSpine:--_currentSpineIndex atPageIndex:targetPage-1];
			}
		}
	}
}

- (int)getGlobalPageCount {
	int pageCount = 0;
	for(int i=0; i<_currentSpineIndex; i++) {
		pageCount += [[_loadedEpub.spineArray objectAtIndex:i] pageCount];
	}
	pageCount += _currentPageInSpineIndex + 1;
	return pageCount;
}

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)gotoPageInCurrentSpine:(int)pageIndex {
	if (pageIndex >= _pagesInCurrentSpineCount) {
		pageIndex = _pagesInCurrentSpineCount - 1;
		_currentPageInSpineIndex = _pagesInCurrentSpineCount - 1;
	}
	float pageOffset = pageIndex*_webView.bounds.size.width;
	NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString* goTo = [NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	[_webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[_webView stringByEvaluatingJavaScriptFromString:goTo];
	if(!_paginating){
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)_totalPagesCount animated:YES];
	}
	_webView.hidden = NO;
}

- (void)gotoNextSpine {
	if (!_paginating) {
		if (_currentSpineIndex+1<[_loadedEpub.spineArray count]) {
			[self loadSpine:++_currentSpineIndex atPageIndex:0];
		}
	}
}

- (void)gotoPrevSpine {
	if (!_paginating) {
		if (_currentSpineIndex-1 >= 0) {
			[self loadSpine:--_currentSpineIndex atPageIndex:0];
		}
	}
}

- (void)updatePagination {
	if (_epubLoaded) {
    if (!_paginating) {
      NSLog(@"Pagination Started!");
      _paginating = YES;
      _totalPagesCount = 0;
      [self loadSpine:_currentSpineIndex atPageIndex:_currentPageInSpineIndex];
      [[_loadedEpub.spineArray objectAtIndex:0] setDelegate:self];
      [[_loadedEpub.spineArray objectAtIndex:0] loadChapterWithWindowSize:_webView.bounds fontPercentSize:_currentTextSize];
      [_currentPageLabel setText:@"?/?"];
    }
	}
}

#pragma mark - Public Methods

- (void)chapterDidFinishLoad:(Chapter *)chapter {
  _totalPagesCount += chapter.pageCount;
	if (chapter.chapterIndex + 1 < [_loadedEpub.spineArray count]) {
		[[_loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] setDelegate:self];
		[[_loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] loadChapterWithWindowSize:_webView.bounds fontPercentSize:_currentTextSize];
		[_currentPageLabel setText:[NSString stringWithFormat:@"?/%d", _totalPagesCount]];
	} else {
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount] / (float)_totalPagesCount animated:YES];
		_paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult *)theResult {
	_webView.hidden = YES;
	self.currentSearchResult = theResult;
	[_chaptersPopover dismissPopoverAnimated:YES];
	[_searchResultsPopover dismissPopoverAnimated:YES];
	NSURL *url = [NSURL fileURLWithPath:[[_loadedEpub.spineArray objectAtIndex:spineIndex] spinePath]];
	[_webView loadRequest:[NSURLRequest requestWithURL:url]];
	_currentPageInSpineIndex = pageIndex;
	_currentSpineIndex = spineIndex;
	if (!_paginating) {
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount] / (float)_totalPagesCount animated:YES];
	}
  NSLog(@"_webView.delegate: %@", _webView.delegate);
}

- (IBAction)increaseTextSizeClicked:(id)sender {
	if (!_paginating) {
		if (_currentTextSize+25 <= 200) {
			_currentTextSize += 25;
			[self updatePagination];
			if (_currentTextSize == 200) {
				[_incTextSizeButton setEnabled:NO];
			}
			[_decTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!_paginating) {
		if (_currentTextSize-25 >= 50) {
			_currentTextSize -= 25;
			[self updatePagination];
			if (_currentTextSize == 50) {
				[_decTextSizeButton setEnabled:NO];
			}
			[_incTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction)doneClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)slidingStarted:(id)sender {
  int targetPage = ((_pageSlider.value/(float)100) * (float)_totalPagesCount);
  if (targetPage == 0) {
    targetPage++;
  }
	[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d", targetPage, _totalPagesCount]];
}

- (IBAction)slidingEnded:(id)sender {
	int targetPage = (int)((_pageSlider.value/(float)100) * (float)_totalPagesCount);
  if (targetPage == 0) {
    targetPage++;
  }
	int pageSum = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
	for (chapterIndex = 0; chapterIndex<[_loadedEpub.spineArray count]; chapterIndex++) {
		pageSum += [[_loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount];
    NSLog(@"Chapter %d, targetPage: %d, pageSum: %d, pageIndex: %d", chapterIndex, targetPage, pageSum, (pageSum-targetPage));
		if(pageSum >= targetPage){
			pageIndex = [[_loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
			break;
		}
	}
	[self loadSpine:chapterIndex atPageIndex:pageIndex];
}

- (IBAction)showChapterIndex:(id)sender {
	if(_chaptersPopover==nil){
		ChapterListViewController *chapterListView = [[ChapterListViewController alloc] init];
		[chapterListView setEpubViewController:self];
		_chaptersPopover = [[UIPopoverController alloc] initWithContentViewController:chapterListView];
		[_chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if ([_chaptersPopover isPopoverVisible]) {
		[_chaptersPopover dismissPopoverAnimated:YES];
	}else{
		[_chaptersPopover presentPopoverFromBarButtonItem:_chapterListButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	if (_searchResultsPopover == nil) {
		_searchResultsPopover = [[UIPopoverController alloc] initWithContentViewController:_searchResViewController];
		[_searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if (![_searchResultsPopover isPopoverVisible]) {
		[_searchResultsPopover presentPopoverFromRect:searchBar.bounds inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
  NSLog(@"Searching for %@", [searchBar text]);
	if (!_searching) {
		_searching = YES;
		[_searchResViewController searchString:[searchBar text]];
    [searchBar resignFirstResponder];
	}
}

# pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"webViewDidFinishLoad:");
	NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
	"mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
	"ruleIndex = mySheet.cssRules.length;"
	"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
	"}"
	"}";
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", _webView.frame.size.height, _webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", _currentTextSize];
	NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];
	[_webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[_webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[_webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[_webView stringByEvaluatingJavaScriptFromString:insertRule2];
	[_webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	[_webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
	if (_currentSearchResult != nil) {
    NSLog(@"Highlighting %@", _currentSearchResult.originatingQuery);
    [_webView highlightAllOccurencesOfString:_currentSearchResult.originatingQuery];
	}
	int totalWidth = [[_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	_pagesInCurrentSpineCount = (int) ((float)totalWidth / _webView.bounds.size.width);
	[self gotoPageInCurrentSpine:_currentPageInSpineIndex];
}

@end
