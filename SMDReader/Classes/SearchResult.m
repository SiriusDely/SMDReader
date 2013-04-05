//
//  SearchResult.m
//  AePubReader
//
//  Created by Federico Frappi on 05/05/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SearchResult.h"

@implementation SearchResult

@synthesize pageIndex = _pageIndex, chapterIndex = _chapterIndex, neighboringText = _neighboringText, hitIndex = _hitIndex, originatingQuery = _originatingQuery;

- initWithChapterIndex:(int)theChapterIndex pageIndex:(int)thePageIndex hitIndex:(int)theHitIndex neighboringText:(NSString *)theNeighboringText originatingQuery:(NSString *)theOriginatingQuery {
  if((self=[super init])){
    _chapterIndex = theChapterIndex;
    _pageIndex = thePageIndex;
    _hitIndex = theHitIndex;
    self.neighboringText = [theNeighboringText stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.originatingQuery = theOriginatingQuery;
  }
  return self;
}

@end
