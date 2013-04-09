//
//  Chapter.h
//  AePubReader
//
//  Created by Federico Frappi on 08/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Chapter;

@protocol ChapterDelegate <NSObject>
@required
- (void)chapterDidFinishLoad:(Chapter *)chapter;
@end

@interface Chapter : NSObject <UIWebViewDelegate>

@property (nonatomic, unsafe_unretained) id delegate;
@property (nonatomic, readonly) int pageCount, chapterIndex, fontPercentSize;
@property (nonatomic, readonly) NSString *spinePath, *title, *text;
@property (nonatomic, readonly) CGRect windowSize;

- (id) initWithPath:(NSString*)theSpinePath title:(NSString *)theTitle chapterIndex:(int)theIndex;

- (void) loadChapterWithWindowSize:(CGRect)theWindowSize fontPercentSize:(int)theFontPercentSize;

@end
