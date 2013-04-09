//
//  Chapter.m
//  AePubReader
//
//  Created by Federico Frappi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Chapter.h"
#import "NSString+HTML.h"

@interface Chapter ()
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation Chapter

@synthesize delegate = _delegate, chapterIndex = _chapterIndex, title = _title, pageCount = _pageCount, spinePath = _spinePath, text = _text,
windowSize = _windowSize, fontPercentSize = _fontPercentSize, webView = _webView;

- (id)initWithPath:(NSString*)theSpinePath title:(NSString *)theTitle chapterIndex:(int)theIndex {
  if (self = [super init]) {
    _spinePath = theSpinePath;
    _title = theTitle;
    _chapterIndex = theIndex;
		NSString* html = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:theSpinePath]] encoding:NSUTF8StringEncoding];
		_text = [html stringByConvertingHTMLToPlainText];
  }
  return self;
}

# pragma mark - Public Methods

- (void)loadChapterWithWindowSize:(CGRect)theWindowSize fontPercentSize:(int)theFontPercentSize {
  NSLog(@"loadChapterWithWindowSize:");
  _fontPercentSize = theFontPercentSize;
  _windowSize = theWindowSize;
  NSLog(@"webview Size: %f * %f, fontPercentSize: %d", theWindowSize.size.width, theWindowSize.size.height, theFontPercentSize);
  _webView = [[UIWebView alloc] initWithFrame:_windowSize];
  [_webView setDelegate:self];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:_spinePath]];
  [_webView loadRequest:urlRequest];
}

# pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"Chapter webViewDidFinishLoad:");
  NSString *varMySheet = @"var mySheet = document.styleSheets[0];";
	NSString *addCSSRule =  @"function addCSSRule(selector, newRule) {"
	"if (mySheet.addRule) {"
  "mySheet.addRule(selector, newRule);"								// For Internet Explorer
	"} else {"
  "ruleIndex = mySheet.cssRules.length;"
  "mySheet.insertRule(selector + '{' + newRule + ';}', ruleIndex);"   // For Firefox, Chrome, etc.
  "}"
	"}";
  NSLog(@"w:%f h:%f", webView.bounds.size.width, webView.bounds.size.height);
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')",_fontPercentSize];
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
  [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	_pageCount = (int)((float)totalWidth/webView.bounds.size.width);
  NSLog(@"Chapter %d: %@ -> %d pages", _chapterIndex, _title, _pageCount);
  [_delegate chapterDidFinishLoad:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"error: %@", error);
}

@end
