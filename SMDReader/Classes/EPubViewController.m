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

@interface EPubViewController () <UIWebViewDelegate, ChapterDelegate, UISearchBarDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) UIView *overlayView;

- (void)gotoNextSpine;
- (void)gotoPrevSpine;
- (void)toggleToolbar;
- (void)gotoNextPage;
- (void)gotoPrevPage;
- (int)getGlobalPageCount;
- (void)gotoPageInCurrentSpine:(int)pageIndex;
- (void)updatePagination;
- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex;

@end

@implementation EPubViewController

@synthesize epub = _epub, toolbar = _toolbar, webView = _webView, overlayView = _overlayView;
@synthesize chapterListButton = _chapterListButton, decTextSizeButton = _decTextSizeButton, incTextSizeButton = _incTextSizeButton;
@synthesize currentPageLabel = _currentPageLabel, pageSlider = _pageSlider;
@synthesize currentSearchResult = _currentSearchResult;
@synthesize chaptersPopover = _chaptersPopover, searchResultsPopover = _searchResultsPopover;
@synthesize searchResViewController = _searchResViewController;
@synthesize currentSpineIndex = _currentSpineIndex, currentPageInSpineIndex = _currentPageInSpineIndex, pagesInCurrentSpineCount = _pagesInCurrentSpineCount,
currentTextSize = _currentTextSize, totalPages = _totalPages;
@synthesize loaded = _loaded, paginating = _paginating, searching = _searching, url = _url;

- (id)initWithUrl:(NSURL *)url {
  if (self = [super init]) {
    _url = url;
  }
  return self;
}

- (void)loadView {
  [super loadView];
  [self.view setBackgroundColor:[UIColor scrollViewTexturedBackgroundColor]];
  _webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x+10.0, self.view.bounds.origin.y+10.0, self.view.bounds.size.width-(2*10.0), self.view.bounds.size.height-(2*10.0))];
  //_webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x+20.0, self.view.bounds.origin.y+44.0+20.0, self.view.bounds.size.width-(2*20.0), 862.0)];
  [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  [_webView setContentMode:UIViewContentModeScaleToFill];
  [self.view addSubview:_webView];
  _overlayView = [[UIView alloc] initWithFrame:_webView.frame];
  [_overlayView setBackgroundColor:[UIColor clearColor]];
  [_overlayView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
  [_overlayView setContentMode:UIViewContentModeScaleToFill];
  [self.view addSubview:_overlayView];
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

# pragma mark - View Lifecycles

- (void)viewDidLoad {
  [super viewDidLoad];
	[_webView setDelegate:self];
	UIScrollView *scrollView = _webView.scrollView;
  scrollView.scrollEnabled = NO;
  scrollView.bounces = NO;
	_currentTextSize = 100;
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleToolbar)];
	UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoNextPage)];
	[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
	UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPrevPage)];
	[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	[_overlayView addGestureRecognizer:tapRecognizer];
	[_overlayView addGestureRecognizer:rightSwipeRecognizer];
	[_overlayView addGestureRecognizer:leftSwipeRecognizer];
	_searchResViewController = [[SearchResultsViewController alloc] init];
	[_searchResViewController setEpubViewController:self];
  _currentSpineIndex = 0;
  _currentPageInSpineIndex = 0;
  _pagesInCurrentSpineCount = 0;
  _totalPages = 0;
	_searching = NO;
  _loaded = NO;
  _epub = [[EPub alloc] initWithUrl:self.url];
  _loaded = YES;
	[self updatePagination];
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

# pragma mark - Autorotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"shouldAutorotateToInterfaceOrientation:");
  [self updatePagination];
	return YES;
}

# pragma mark - Private Methods

- (void)toggleToolbar {
  if (self.toolbar.hidden) {
    [self.toolbar setHidden:!self.toolbar.hidden];
    [self.currentPageLabel setHidden:!self.currentPageLabel.hidden];
    [self.pageSlider setHidden:!self.pageSlider.hidden];
    [UIView animateWithDuration:0.5f animations:^ {
      [self.toolbar setAlpha:0.8];
      [self.currentPageLabel setAlpha:0.8];
      [self.pageSlider setAlpha:0.8];
    } completion:^(BOOL finished) {
      
    }];
  } else {
    [UIView animateWithDuration:0.5f animations:^ {
      [self.toolbar setAlpha:0.0];
      [self.currentPageLabel setAlpha:0.0];
      [self.pageSlider setAlpha:0.0];
    } completion:^(BOOL finished) {
      [self.toolbar setHidden:!self.toolbar.hidden];
      [self.currentPageLabel setHidden:!self.currentPageLabel.hidden];
      [self.pageSlider setHidden:!self.pageSlider.hidden];
    }];
  }
}

- (void)gotoNextPage {
	if (!self.paginating) {
		if (self.currentPageInSpineIndex+1 < self.pagesInCurrentSpineCount) {
			[self gotoPageInCurrentSpine:++self.currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}
	}
}

- (void)gotoPrevPage {
	if (!self.paginating) {
		if (self.currentPageInSpineIndex-1 >= 0) {
			[self gotoPageInCurrentSpine:--self.currentPageInSpineIndex];
		} else {
			if (self.currentSpineIndex != 0) {
				int targetPage = [[self.epub.chapters objectAtIndex:(self.currentSpineIndex-1)] pages];
				[self loadSpine:--self.currentSpineIndex atPageIndex:targetPage-1];
			}
		}
	}
}

- (int)getGlobalPageCount {
	int pages = 0;
	for(int i=0; i<self.currentSpineIndex; i++) {
		pages += [[self.epub.chapters objectAtIndex:i] pages];
	}
	pages += self.currentPageInSpineIndex + 1;
	return pages;
}

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void)gotoPageInCurrentSpine:(int)pageIndex {
	if (pageIndex >= self.pagesInCurrentSpineCount) {
		pageIndex = self.pagesInCurrentSpineCount-1;
		self.currentPageInSpineIndex = self.pagesInCurrentSpineCount-1;
	}
	float pageOffset = pageIndex * self.webView.bounds.size.width;
	NSString *goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString *goTo = [NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	[self.webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[self.webView stringByEvaluatingJavaScriptFromString:goTo];
	if(!self.paginating){
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPages]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPages animated:YES];
	}
	self.webView.hidden = NO;
}

- (void)gotoNextSpine {
	if (!self.paginating) {
		if (self.currentSpineIndex+1<[_epub.chapters count]) {
			[self loadSpine:++self.currentSpineIndex atPageIndex:0];
		}
	}
}

- (void)gotoPrevSpine {
	if (!self.paginating) {
		if (self.currentSpineIndex-1 >= 0) {
			[self loadSpine:--self.currentSpineIndex atPageIndex:0];
		}
	}
}

- (void)updatePagination {
	if (self.loaded) {
    if (!self.paginating) {
      NSLog(@"Pagination Started!");
      self.paginating = YES;
      self.totalPages = 0;
      [self loadSpine:self.currentSpineIndex atPageIndex:self.currentPageInSpineIndex];
      [[self.epub.chapters objectAtIndex:0] setDelegate:self];
      [[self.epub.chapters objectAtIndex:0] loadChapterWithWindowSize:self.webView.bounds fontPercentSize:self.currentTextSize];
      [self.currentPageLabel setText:@"?/?"];
    }
	}
}

# pragma mark - Public Methods

- (void)loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult *)result {
	self.webView.hidden = YES;
	self.currentSearchResult = result;
	[self.chaptersPopover dismissPopoverAnimated:YES];
	[self.searchResultsPopover dismissPopoverAnimated:YES];
	NSURL *url = [NSURL fileURLWithPath:[[self.epub.chapters objectAtIndex:spineIndex] path]];
	[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	self.currentPageInSpineIndex = pageIndex;
	self.currentSpineIndex = spineIndex;
	if (!self.paginating) {
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPages]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPages animated:YES];
	}
}

- (IBAction)increaseTextSizeClicked:(id)sender {
	if (!self.paginating) {
		if (self.currentTextSize+25 <= 200) {
			self.currentTextSize += 25;
			[self updatePagination];
			if (self.currentTextSize == 200) {
				[self.incTextSizeButton setEnabled:NO];
			}
			[self.decTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction)decreaseTextSizeClicked:(id)sender {
	if (!self.paginating) {
		if (self.currentTextSize-25 >= 50) {
			self.currentTextSize -= 25;
			[self updatePagination];
			if (self.currentTextSize == 50) {
				[self.decTextSizeButton setEnabled:NO];
			}
			[self.incTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction)doneClicked:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)slidingStarted:(id)sender {
  int targetPage = ((self.pageSlider.value/(float)100) * (float)self.totalPages);
  if (targetPage == 0) {
    targetPage++;
  }
	[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d", targetPage, self.totalPages]];
}

- (IBAction)slidingEnded:(id)sender {
	int targetPage = (int)((self.pageSlider.value/(float)100) * (float)self.totalPages);
  if (targetPage == 0) {
    targetPage++;
  }
	int pageSum = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
	for (chapterIndex = 0; chapterIndex<[self.epub.chapters count]; chapterIndex++) {
		pageSum += [[self.epub.chapters objectAtIndex:chapterIndex] pages];
    NSLog(@"Chapter %d, targetPage: %d, pageSum: %d, pageIndex: %d", chapterIndex, targetPage, pageSum, (pageSum-targetPage));
		if(pageSum >= targetPage){
			pageIndex = [[self.epub.chapters objectAtIndex:chapterIndex] pages] - 1 - pageSum + targetPage;
			break;
		}
	}
	[self loadSpine:chapterIndex atPageIndex:pageIndex];
}

- (IBAction)showChapterIndex:(id)sender {
	if(_chaptersPopover == nil){
		ChapterListViewController *chapterListView = [[ChapterListViewController alloc] init];
		[chapterListView setEpubViewController:self];
		_chaptersPopover = [[UIPopoverController alloc] initWithContentViewController:chapterListView];
		[_chaptersPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if ([self.chaptersPopover isPopoverVisible]) {
		[self.chaptersPopover dismissPopoverAnimated:YES];
	}else{
		[self.chaptersPopover presentPopoverFromBarButtonItem:self.chapterListButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	if (_searchResultsPopover == nil) {
		_searchResultsPopover = [[UIPopoverController alloc] initWithContentViewController:_searchResViewController];
		[_searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if (![self.searchResultsPopover isPopoverVisible]) {
		[self.searchResultsPopover presentPopoverFromRect:searchBar.bounds inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
  NSLog(@"Searching for %@", [searchBar text]);
	if (!self.searching) {
		self.searching = YES;
		[self.searchResViewController searchString:[searchBar text]];
    [searchBar resignFirstResponder];
	}
}

# pragma mark - ChapterDelegate

- (void)chapterDidFinishLoad:(Chapter *)chapter {
  self.totalPages += chapter.pages;
	if (chapter.index + 1 < [self.epub.chapters count]) {
		[[self.epub.chapters objectAtIndex:chapter.index+1] setDelegate:self];
		[[self.epub.chapters objectAtIndex:chapter.index+1] loadChapterWithWindowSize:self.webView.bounds fontPercentSize:self.currentTextSize];
		[self.currentPageLabel setText:[NSString stringWithFormat:@"?/%d", _totalPages]];
	} else {
		[self.currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], self.totalPages]];
		[self.pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)self.totalPages animated:YES];
		self.paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

# pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
	"mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
	"ruleIndex = mySheet.cssRules.length;"
	"mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
	"}"
	"}";
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.currentTextSize];
	NSString *setHighlightColorRule = [NSString stringWithFormat:@"addCSSRule('highlight', 'background-color: yellow;')"];
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
	[webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	[webView stringByEvaluatingJavaScriptFromString:setHighlightColorRule];
	if (self.currentSearchResult != nil) {
    NSLog(@"Highlighting %@", self.currentSearchResult.originatingQuery);
    [webView highlightAllOccurencesOfString:self.currentSearchResult.originatingQuery];
	}
	int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	self.pagesInCurrentSpineCount = (int)((float)totalWidth/webView.bounds.size.width);
	[self gotoPageInCurrentSpine:self.currentPageInSpineIndex];
}

@end
