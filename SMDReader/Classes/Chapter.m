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

@synthesize delegate = _delegate, index = _index, title = _title, pages = _pages, path = _path, text = _text,
windowSize = _windowSize, fontPercentSize = _fontPercentSize, webView = _webView;

- (id)initWithPath:(NSString*)path title:(NSString *)title chapterIndex:(int)index {
  if (self = [super init]) {
    _path = path;
    _title = title;
    _index = index;
		NSString *html = [[NSString alloc] initWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:path]] encoding:NSUTF8StringEncoding];
		_text = [html stringByConvertingHTMLToPlainText];
  }
  return self;
}

# pragma mark - Public Methods

- (void)loadChapterWithWindowSize:(CGRect)windowSize fontPercentSize:(int)fontPercentSize {
  _fontPercentSize = fontPercentSize;
  _windowSize = windowSize;
  _webView = [[UIWebView alloc] initWithFrame:_windowSize];
  [_webView setDelegate:self];
  NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL fileURLWithPath:_path]];
  [_webView loadRequest:urlRequest];
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
  // NSLog(@"webview Size: %f * %f, fontPercentSize: %d", webView.bounds.size.width, webView.bounds.size.height, self.fontPercentSize);
	NSString *insertRule1 = [NSString stringWithFormat:@"addCSSRule('html', 'padding: 0px; height: %fpx; -webkit-column-gap: 0px; -webkit-column-width: %fpx;')", webView.frame.size.height, webView.frame.size.width];
	NSString *insertRule2 = [NSString stringWithFormat:@"addCSSRule('p', 'text-align: justify;')"];
	NSString *setTextSizeRule = [NSString stringWithFormat:@"addCSSRule('body', '-webkit-text-size-adjust: %d%%;')", self.fontPercentSize];
	[webView stringByEvaluatingJavaScriptFromString:varMySheet];
	[webView stringByEvaluatingJavaScriptFromString:addCSSRule];
	[webView stringByEvaluatingJavaScriptFromString:insertRule1];
	[webView stringByEvaluatingJavaScriptFromString:insertRule2];
  [webView stringByEvaluatingJavaScriptFromString:setTextSizeRule];
	int totalWidth = [[webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.scrollWidth"] intValue];
	_pages = (int)((float)totalWidth / webView.bounds.size.width);
  // NSLog(@"Chapter %d: %@ -> %d pages", _index, _title, _pages);
  [_delegate chapterDidFinishLoad:self];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"error: %@", error);
}

@end
