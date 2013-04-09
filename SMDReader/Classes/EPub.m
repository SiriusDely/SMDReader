//
//  EPub.m
//  AePubReader
//
//  Created by Federico Frappi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EPub.h"
#import <ZipArchive.h>
#import "Chapter.h"

@interface EPub ()
- (void)parseEpub;
- (void)unzipAndSaveFileNamed:(NSString *)fileName;
- (NSString *)applicationDocumentsDirectory;
- (NSString *)parseManifestFile;
- (void)parseOPF:(NSString *)opfPath;
@end

@implementation EPub

@synthesize spineArray = _spineArray, epubFilePath = _epubFilePath;

- (id)initWithEPubPath:(NSString *)path {
	if(self = [super init]){
		_epubFilePath = path;
		_spineArray = [[NSMutableArray alloc] init];
		[self parseEpub];
	}
	return self;
}

# pragma mark - Private Methods

- (void)parseEpub {
	[self unzipAndSaveFileNamed:_epubFilePath];
	NSString *opfPath = [self parseManifestFile];
	[self parseOPF:opfPath];
}

- (void)unzipAndSaveFileNamed:(NSString *)fileName {
	ZipArchive *zipArchive = [[ZipArchive alloc] init];
  NSLog(@"unzipping: %@", fileName);
	if([zipArchive UnzipOpenFile:fileName]){
		NSString *strPath = [NSString stringWithFormat:@"%@/UnzippedEpub", [self applicationDocumentsDirectory]];
    NSLog(@"strPath: %@", strPath);
		// Delete all the previous files
		NSFileManager *filemanager = [[NSFileManager alloc] init];
		if ([filemanager fileExistsAtPath:strPath]) {
			NSError *error;
			[filemanager removeItemAtPath:strPath error:&error];
		}
		// start unzip
		BOOL success = [zipArchive UnzipFileTo:[NSString stringWithFormat:@"%@/",strPath] overWrite:YES];
		if(!success) {
			// error handler here
      NSLog(@"Error while unzipping the epub");
		}
		[zipArchive UnzipCloseFile];
	}
}

- (NSString *)applicationDocumentsDirectory {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
  return basePath;
}

- (NSString *)parseManifestFile {
	NSString *manifestFilePath = [NSString stringWithFormat:@"%@/UnzippedEpub/META-INF/container.xml", [self applicationDocumentsDirectory]];
  NSLog(@"manifestFilePath: %@", manifestFilePath);
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:manifestFilePath]) {
    NSLog(@"Valid epub");
		CXMLDocument* manifestFile = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:manifestFilePath] options:0 error:nil];
		CXMLNode* opfPath = [manifestFile nodeForXPath:@"//@full-path[1]" error:nil];
    NSLog(@"return: %@", [NSString stringWithFormat:@"%@/UnzippedEpub/%@", [self applicationDocumentsDirectory], [opfPath stringValue]]);
		return [NSString stringWithFormat:@"%@/UnzippedEpub/%@", [self applicationDocumentsDirectory], [opfPath stringValue]];
	} else {
		NSLog(@"ERROR: ePub not Valid");
		return nil;
	}
}

- (void)parseOPF:(NSString *)opfPath {
	CXMLDocument *opfFile = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:opfPath] options:0 error:nil];
	NSArray *itemsArray = [opfFile nodesForXPath:@"//opf:item" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"] error:nil];
  NSLog(@"itemsArray size: %d", [itemsArray count]);
  NSString* ncxFileName;
  NSMutableDictionary* itemDictionary = [[NSMutableDictionary alloc] init];
	for (CXMLElement* element in itemsArray) {
		[itemDictionary setValue:[[element attributeForName:@"href"] stringValue] forKey:[[element attributeForName:@"id"] stringValue]];
    if([[[element attributeForName:@"media-type"] stringValue] isEqualToString:@"application/x-dtbncx+xml"]){
      ncxFileName = [[element attributeForName:@"href"] stringValue];
      NSLog(@"%@ : %@", [[element attributeForName:@"id"] stringValue], [[element attributeForName:@"href"] stringValue]);
    }
    if([[[element attributeForName:@"media-type"] stringValue] isEqualToString:@"application/xhtml+xml"]){
      ncxFileName = [[element attributeForName:@"href"] stringValue];
      NSLog(@"%@ : %@", [[element attributeForName:@"id"] stringValue], [[element attributeForName:@"href"] stringValue]);
    }
	}
  int lastSlash = [opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
	NSString *ebookBasePath = [opfPath substringToIndex:(lastSlash +1)];
  CXMLDocument *ncxToc = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName]] options:0 error:nil];
  NSMutableDictionary *titleDictionary = [[NSMutableDictionary alloc] init];
  for (CXMLElement *element in itemsArray) {
    NSString *href = [[element attributeForName:@"href"] stringValue];
    NSString *xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
    NSArray *navPoints = [ncxToc nodesForXPath:xpath namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"] error:nil];
    if([navPoints count]!=0){
      CXMLElement *titleElement = [navPoints objectAtIndex:0];
      [titleDictionary setValue:[titleElement stringValue] forKey:href];
    }
  }
	NSArray* itemRefsArray = [opfFile nodesForXPath:@"//opf:itemref" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"] error:nil];
  NSLog(@"itemRefsArray size: %d", [itemRefsArray count]);
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  int count = 0;
	for (CXMLElement *element in itemRefsArray) {
    NSString *chapHref = [itemDictionary valueForKey:[[element attributeForName:@"idref"] stringValue]];
    Chapter *tmpChapter = [[Chapter alloc] initWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, chapHref]
                                                  title:[titleDictionary valueForKey:chapHref]
                                           chapterIndex:count++];
		[tmpArray addObject:tmpChapter];
	}
	self.spineArray = [NSArray arrayWithArray:tmpArray];
}

@end
