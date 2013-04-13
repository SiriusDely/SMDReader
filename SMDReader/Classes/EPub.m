//
//  EPub.m
//  AePubReader
//
//  Created by Federico Frappi on 05/04/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <ZipArchive.h>
#import "EPub.h"
#import "Chapter.h"

@interface EPub ()

@property(nonatomic, strong) NSString *path;
@property(nonatomic, strong) NSString *opfPath;

- (void)parse;
- (void)unzip;
- (void)parseManifest;
- (void)parseOpf;
- (NSString *)applicationDocumentsDirectoryPath;

@end

@implementation EPub

@synthesize spineArray = _spineArray, path = _path, opfPath = _opfPath;

- (id)initWithUrl:(NSURL *)url {
	if(self = [super init]){
		_path = url.path;
		_spineArray = [[NSMutableArray alloc] init];
		[self parse];
	}
	return self;
}

# pragma mark - Private Methods

- (void)parse {
	[self unzip];
	[self parseManifest];
	[self parseOpf];
}

- (void)unzip {
	ZipArchive *zipArchive = [[ZipArchive alloc] init];
  NSLog(@"unzipping: %@", self.path);
	if([zipArchive UnzipOpenFile:self.path]){
		NSString *path = [NSString stringWithFormat:@"%@/SMDSocialReader/EPub", [self applicationDocumentsDirectoryPath]];
    NSLog(@"path: %@", path);
		// Delete all the previous files
		NSFileManager *fileManager = [[NSFileManager alloc] init];
		if ([fileManager fileExistsAtPath:path]) {
			NSError *error;
			[fileManager removeItemAtPath:path error:&error];
		}
		// start unzip
		BOOL success = [zipArchive UnzipFileTo:[NSString stringWithFormat:@"%@/", path] overWrite:YES];
		if(!success) {
			// error handler here
      NSLog(@"Error while unzipping the epub");
		}
		[zipArchive UnzipCloseFile];
	}
}

- (NSString *)applicationDocumentsDirectoryPath {
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
  return path;
}

- (void)parseManifest {
	NSString *path = [NSString stringWithFormat:@"%@/SMDSocialReader/EPub/META-INF/container.xml", [self applicationDocumentsDirectoryPath]];
  NSLog(@"manifestPath: %@", path);
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:path]) {
    NSLog(@"Valid epub");
		CXMLDocument* manifestDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path] options:0 error:nil];
		CXMLNode* opfNode = [manifestDocument nodeForXPath:@"//@full-path[1]" error:nil];
    NSString *opfPath = [NSString stringWithFormat:@"%@/SMDSocialReader/EPub/%@", [self applicationDocumentsDirectoryPath], [opfNode stringValue]];
    NSLog(@"opfPath: %@", opfPath);
    self.opfPath = opfPath;
	} else {
		NSLog(@"ERROR: ePub not Valid");
	}
}

- (void)parseOpf {
	CXMLDocument *opfDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.opfPath] options:0 error:nil];
	NSArray *itemsArray = [opfDocument nodesForXPath:@"//opf:item" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]
                                             error:nil];
  NSLog(@"itemsArray size: %d", [itemsArray count]);
  NSString *ncxFileName;
  NSMutableDictionary *itemDictionary = [[NSMutableDictionary alloc] init];
	for (CXMLElement *element in itemsArray) {
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
  int lastSlash = [self.opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
	NSString *ebookBasePath = [self.opfPath substringToIndex:(lastSlash +1)];
  CXMLDocument *ncxToc = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, ncxFileName]]
                                                             options:0 error:nil];
  NSMutableDictionary *titleDictionary = [[NSMutableDictionary alloc] init];
  for (CXMLElement *element in itemsArray) {
    NSString *href = [[element attributeForName:@"href"] stringValue];
    NSString *xpath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
    NSArray *navPoints = [ncxToc nodesForXPath:xpath namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"]
                                         error:nil];
    if([navPoints count]!=0){
      CXMLElement *titleElement = [navPoints objectAtIndex:0];
      [titleDictionary setValue:[titleElement stringValue] forKey:href];
    }
  }
	NSArray *itemRefsArray = [opfDocument nodesForXPath:@"//opf:itemref" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]
                                                error:nil];
  NSLog(@"itemRefsArray size: %d", [itemRefsArray count]);
	NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
  int count = 0;
	for (CXMLElement *element in itemRefsArray) {
    NSString *chapHref = [itemDictionary valueForKey:[[element attributeForName:@"idref"] stringValue]];
    Chapter *chapter = [[Chapter alloc] initWithPath:[NSString stringWithFormat:@"%@%@", ebookBasePath, chapHref]
                                               title:[titleDictionary valueForKey:chapHref] chapterIndex:count++];
		[tmpArray addObject:chapter];
	}
	self.spineArray = [NSArray arrayWithArray:tmpArray];
}

@end
