//
//  SearchResultsViewController.m
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchResultsViewController.h"
#import "SearchResult.h"
#import "UIWebView+SearchWebView.h"

@interface SearchResultsViewController()
- (void)searchString:(NSString *)query inChapterAtIndex:(int)index;
@end


@implementation SearchResultsViewController

@synthesize resultsTableView = _resultsTableView, epubViewController = _epubViewController, currentQuery = _currentQuery,
results = _results, currentChapterIndex = _currentChapterIndex;

# pragma mark - View lifecycles

- (void)loadView {
  [super loadView];
  _resultsTableView = [[UITableView alloc] initWithFrame:self.view.bounds];
}

- (void)viewDidUnload {
  [super viewDidUnload];
  self.resultsTableView = nil;
}

# pragma mark - Private Methods

- (void)searchString:(NSString *)query inChapterAtIndex:(int)index {
  _currentChapterIndex = index;
  Chapter *chapter = [_epubViewController.epub.chapters objectAtIndex:index];
  NSRange range = NSMakeRange(0, chapter.text.length);
  range = [chapter.text rangeOfString:query options:NSCaseInsensitiveSearch range:range locale:nil];
  int hitCount = 0;
  while (range.location != NSNotFound) {
    range = NSMakeRange(range.location+range.length, chapter.text.length-(range.location+range.length));
    range = [chapter.text rangeOfString:query options:NSCaseInsensitiveSearch range:range locale:nil];
    hitCount++;
  }
  if (hitCount != 0) {
    UIWebView *webView = [[UIWebView alloc] initWithFrame:chapter.windowSize];
    [webView setDelegate:self];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:chapter.path]];
    [webView loadRequest:urlRequest];
  } else {
    if((_currentChapterIndex+1)<[_epubViewController.epub.chapters count]){
      [self searchString:_currentQuery inChapterAtIndex:(_currentChapterIndex+1)];
    } else {
      _epubViewController.searching = NO;
    }
  }
}

# pragma mark - Public Methods

- (void) searchString:(NSString*)query{
  self.results = [[NSMutableArray alloc] init];
  [_resultsTableView reloadData];
  self.currentQuery = query;
  [self searchString:query inChapterAtIndex:0];
}

# pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
  }
  cell.textLabel.adjustsFontSizeToFitWidth = YES;
  SearchResult* hit = (SearchResult*)[_results objectAtIndex:[indexPath row]];
  cell.textLabel.text = [NSString stringWithFormat:@"...%@...", hit.neighboringText];
  cell.detailTextLabel.text = [NSString stringWithFormat:@"Chapter %d - page %d", hit.chapterIndex, hit.pageIndex+1];
  return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_results count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
  SearchResult* hit = (SearchResult*)[_results objectAtIndex:[indexPath row]];
  [_epubViewController loadSpine:hit.chapterIndex atPageIndex:hit.pageIndex highlightSearchResult:hit];
}

# pragma mark - UIWebViewDelegate

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"%@", error);
}

- (void) webViewDidFinishLoad:(UIWebView*)webView {
  NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
  "mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
  "ruleIndex = mySheet.cssRules.length;"
  "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
  "}"
	"}";
	
  //    NSLog(@"w:%f h:%f", webView.bounds.size.width, webView.bounds.size.height);
	
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')",[[_epubViewController.epub.chapters objectAtIndex:_currentChapterIndex] fontPercentSize]];
  
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
  [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
  
  [webView highlightAllOccurencesOfString:_currentQuery];
  
  NSString* foundHits = [webView stringByEvaluatingJavaScriptFromString:@"results"];
  
  //    NSLog(@"%@", foundHits);
  
  NSMutableArray* objects = [[NSMutableArray alloc] init];
  
  NSArray* stringObjects = [foundHits componentsSeparatedByString:@";"];
  for(int i=0; i<[stringObjects count]; i++){
    NSArray* strObj = [[stringObjects objectAtIndex:i] componentsSeparatedByString:@","];
    if([strObj count]==3){
      [objects addObject:strObj];
    }
  }
  
  NSArray* orderedRes = [objects sortedArrayUsingComparator:^(id obj1, id obj2){
    int x1 = [[obj1 objectAtIndex:0] intValue];
    int x2 = [[obj2 objectAtIndex:0] intValue];
    int y1 = [[obj1 objectAtIndex:1] intValue];
    int y2 = [[obj2 objectAtIndex:1] intValue];
    if(y1<y2){
      return NSOrderedAscending;
    } else if(y1>y2){
      return NSOrderedDescending;
    } else {
      if(x1<x2){
        return NSOrderedAscending;
      } else if (x1>x2){
        return NSOrderedDescending;
      } else {
        return NSOrderedSame;
      }
    }
  }];
    
  for(int i=0; i<[orderedRes count]; i++) {
    NSArray* currObj = [orderedRes objectAtIndex:i];
    SearchResult* searchRes = [[SearchResult alloc] initWithChapterIndex:_currentChapterIndex pageIndex:([[currObj objectAtIndex:1] intValue]/webView.bounds.size.height) hitIndex:0 neighboringText:[webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"unescape('%@')", [currObj objectAtIndex:2]]] originatingQuery:_currentQuery];
    [_results addObject:searchRes];
  }
    
  [_resultsTableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
  if((_currentChapterIndex+1)<[_epubViewController.epub.chapters count]) {
    [self searchString:_currentQuery inChapterAtIndex:(_currentChapterIndex+1)];
  } else {
    _epubViewController.searching = NO;
  }
}

@end
