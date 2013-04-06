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

@interface EPubViewController()

- (void) gotoNextSpine;
- (void) gotoPrevSpine;
- (void) gotoNextPage;
- (void) gotoPrevPage;

- (int) getGlobalPageCount;

- (void) gotoPageInCurrentSpine: (int)pageIndex;
- (void) updatePagination;

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex;


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
@synthesize epubLoaded = _epubLoaded, paginating = _paginating, searching = _searching;

#pragma mark -

- (void) loadEpub:(NSURL*) epubURL{
  _currentSpineIndex = 0;
  _currentPageInSpineIndex = 0;
  _pagesInCurrentSpineCount = 0;
  _totalPagesCount = 0;
	_searching = NO;
  _epubLoaded = NO;
  self.loadedEpub = [[EPub alloc] initWithEPubPath:[epubURL path]];
  _epubLoaded = YES;
  NSLog(@"loadEpub");
	[self updatePagination];
}

- (void) chapterDidFinishLoad:(Chapter *)chapter{
  _totalPagesCount+=chapter.pageCount;
  
	if(chapter.chapterIndex + 1 < [_loadedEpub.spineArray count]){
		[[_loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] setDelegate:self];
		[[_loadedEpub.spineArray objectAtIndex:chapter.chapterIndex+1] loadChapterWithWindowSize:_webView.bounds fontPercentSize:_currentTextSize];
		[_currentPageLabel setText:[NSString stringWithFormat:@"?/%d", _totalPagesCount]];
	} else {
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)_totalPagesCount animated:YES];
		_paginating = NO;
		NSLog(@"Pagination Ended!");
	}
}

- (int) getGlobalPageCount{
	int pageCount = 0;
	for(int i=0; i<_currentSpineIndex; i++){
		pageCount+= [[_loadedEpub.spineArray objectAtIndex:i] pageCount];
	}
	pageCount+=_currentPageInSpineIndex+1;
	return pageCount;
}

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex {
	[self loadSpine:spineIndex atPageIndex:pageIndex highlightSearchResult:nil];
}

- (void) loadSpine:(int)spineIndex atPageIndex:(int)pageIndex highlightSearchResult:(SearchResult*)theResult{
	
	_webView.hidden = YES;
	
	self.currentSearchResult = theResult;
  
	[_chaptersPopover dismissPopoverAnimated:YES];
	[_searchResultsPopover dismissPopoverAnimated:YES];
	
	NSURL* url = [NSURL fileURLWithPath:[[_loadedEpub.spineArray objectAtIndex:spineIndex] spinePath]];
	[_webView loadRequest:[NSURLRequest requestWithURL:url]];
	_currentPageInSpineIndex = pageIndex;
	_currentSpineIndex = spineIndex;
	if(!_paginating){
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)_totalPagesCount animated:YES];
	}
}

- (void) gotoPageInCurrentSpine:(int)pageIndex{
	if(pageIndex>=_pagesInCurrentSpineCount){
		pageIndex = _pagesInCurrentSpineCount - 1;
		_currentPageInSpineIndex = _pagesInCurrentSpineCount - 1;
	}
	
	float pageOffset = pageIndex*_webView.bounds.size.width;
  
	NSString* goToOffsetFunc = [NSString stringWithFormat:@" function pageScroll(xOffset){ window.scroll(xOffset,0); } "];
	NSString* goTo =[NSString stringWithFormat:@"pageScroll(%f)", pageOffset];
	
	[_webView stringByEvaluatingJavaScriptFromString:goToOffsetFunc];
	[_webView stringByEvaluatingJavaScriptFromString:goTo];
	
	if(!_paginating){
		[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d",[self getGlobalPageCount], _totalPagesCount]];
		[_pageSlider setValue:(float)100*(float)[self getGlobalPageCount]/(float)_totalPagesCount animated:YES];
	}
	
	_webView.hidden = NO;
	
}

- (void) gotoNextSpine {
	if(!_paginating){
		if(_currentSpineIndex+1<[_loadedEpub.spineArray count]){
			[self loadSpine:++_currentSpineIndex atPageIndex:0];
		}
	}
}

- (void) gotoPrevSpine {
	if(!_paginating){
		if(_currentSpineIndex-1>=0){
			[self loadSpine:--_currentSpineIndex atPageIndex:0];
		}
	}
}

- (void) gotoNextPage {
	if(!_paginating){
		if(_currentPageInSpineIndex+1<_pagesInCurrentSpineCount){
			[self gotoPageInCurrentSpine:++_currentPageInSpineIndex];
		} else {
			[self gotoNextSpine];
		}
	}
}

- (void) gotoPrevPage {
	if (!_paginating) {
		if(_currentPageInSpineIndex-1>=0){
			[self gotoPageInCurrentSpine:--_currentPageInSpineIndex];
		} else {
			if(_currentSpineIndex!=0){
				int targetPage = [[_loadedEpub.spineArray objectAtIndex:(_currentSpineIndex-1)] pageCount];
				[self loadSpine:--_currentSpineIndex atPageIndex:targetPage-1];
			}
		}
	}
}


- (IBAction) increaseTextSizeClicked:(id)sender{
	if(!_paginating){
		if(_currentTextSize+25<=200){
			_currentTextSize+=25;
			[self updatePagination];
			if(_currentTextSize == 200){
				[_incTextSizeButton setEnabled:NO];
			}
			[_decTextSizeButton setEnabled:YES];
		}
	}
}
- (IBAction) decreaseTextSizeClicked:(id)sender{
	if(!_paginating){
		if(_currentTextSize-25>=50){
			_currentTextSize-=25;
			[self updatePagination];
			if(_currentTextSize==50){
				[_decTextSizeButton setEnabled:NO];
			}
			[_incTextSizeButton setEnabled:YES];
		}
	}
}

- (IBAction) doneClicked:(id)sender{
  [self dismissModalViewControllerAnimated:YES];
}


- (IBAction) slidingStarted:(id)sender{
  int targetPage = ((_pageSlider.value/(float)100)*(float)_totalPagesCount);
  if (targetPage==0) {
    targetPage++;
  }
	[_currentPageLabel setText:[NSString stringWithFormat:@"%d/%d", targetPage, _totalPagesCount]];
}

- (IBAction) slidingEnded:(id)sender{
	int targetPage = (int)((_pageSlider.value/(float)100)*(float)_totalPagesCount);
  if (targetPage==0) {
    targetPage++;
  }
	int pageSum = 0;
	int chapterIndex = 0;
	int pageIndex = 0;
	for(chapterIndex=0; chapterIndex<[_loadedEpub.spineArray count]; chapterIndex++){
		pageSum+=[[_loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount];
    //		NSLog(@"Chapter %d, targetPage: %d, pageSum: %d, pageIndex: %d", chapterIndex, targetPage, pageSum, (pageSum-targetPage));
		if(pageSum>=targetPage){
			pageIndex = [[_loadedEpub.spineArray objectAtIndex:chapterIndex] pageCount] - 1 - pageSum + targetPage;
			break;
		}
	}
	[self loadSpine:chapterIndex atPageIndex:pageIndex];
}

- (IBAction) showChapterIndex:(id)sender{
	if(_chaptersPopover==nil){
		ChapterListViewController* chapterListView = [[ChapterListViewController alloc] init];
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


- (void)webViewDidFinishLoad:(UIWebView *)theWebView{
	
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
	
	if(_currentSearchResult!=nil){
    //	NSLog(@"Highlighting %@", currentSearchResult.originatingQuery);
    [_webView highlightAllOccurencesOfString:_currentSearchResult.originatingQuery];
	}
	
	
	int totalWidth = [[_webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	_pagesInCurrentSpineCount = (int)((float)totalWidth/_webView.bounds.size.width);
	
	[self gotoPageInCurrentSpine:_currentPageInSpineIndex];
}

- (void) updatePagination{
	if(_epubLoaded){
    if(!_paginating){
      NSLog(@"Pagination Started!");
      _paginating = YES;
      _totalPagesCount=0;
      [self loadSpine:_currentSpineIndex atPageIndex:_currentPageInSpineIndex];
      [[_loadedEpub.spineArray objectAtIndex:0] setDelegate:self];
      [[_loadedEpub.spineArray objectAtIndex:0] loadChapterWithWindowSize:_webView.bounds fontPercentSize:_currentTextSize];
      [_currentPageLabel setText:@"?/?"];
    }
	}
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
	if(_searchResultsPopover==nil){
		_searchResultsPopover = [[UIPopoverController alloc] initWithContentViewController:_searchResViewController];
		[_searchResultsPopover setPopoverContentSize:CGSizeMake(400, 600)];
	}
	if (![_searchResultsPopover isPopoverVisible]) {
		[_searchResultsPopover presentPopoverFromRect:searchBar.bounds inView:searchBar permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
  //	NSLog(@"Searching for %@", [searchBar text]);
	if(!_searching){
		_searching = YES;
		[_searchResViewController searchString:[searchBar text]];
    [searchBar resignFirstResponder];
	}
}


#pragma mark -
#pragma mark Rotation support

// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  NSLog(@"shouldAutorotate");
  [self updatePagination];
	return YES;
}

#pragma mark -
#pragma mark View lifecycles

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
  [super viewDidLoad];
	[_webView setDelegate:self];
  
	UIScrollView* sv = nil;
	for (UIView* v in  _webView.subviews) {
		if([v isKindOfClass:[UIScrollView class]]){
			sv = (UIScrollView*) v;
			sv.scrollEnabled = NO;
			sv.bounces = NO;
		}
	}
	_currentTextSize = 100;
	
	UISwipeGestureRecognizer* rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoNextPage)];
	[rightSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	UISwipeGestureRecognizer* leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPrevPage)];
	[leftSwipeRecognizer setDirection:UISwipeGestureRecognizerDirectionRight];
	
	[_webView addGestureRecognizer:rightSwipeRecognizer];
	[_webView addGestureRecognizer:leftSwipeRecognizer];
	
	[_pageSlider setThumbImage:[UIImage imageNamed:@"slider_ball.png"] forState:UIControlStateNormal];
	[_pageSlider setMinimumTrackImage:[[UIImage imageNamed:@"orangeSlide.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
	[_pageSlider setMaximumTrackImage:[[UIImage imageNamed:@"yellowSlide.png"] stretchableImageWithLeftCapWidth:10 topCapHeight:0] forState:UIControlStateNormal];
  
	_searchResViewController = [[SearchResultsViewController alloc] init];
	_searchResViewController.epubViewController = self;
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

@end
