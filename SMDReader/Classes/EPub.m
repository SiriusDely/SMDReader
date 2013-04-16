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

@synthesize chapters = _chapters, path = _path, opfPath = _opfPath;

- (id)initWithFilePath:(NSString *)path {
	if(self = [super init]){
		_path = path;
		_chapters = [[NSMutableArray alloc] init];
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
		NSString *path = [NSString stringWithFormat:@"%@/UnZippedEPub", [self applicationDocumentsDirectoryPath]];
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
	NSString *containerPath = [NSString stringWithFormat:@"%@/UnZippedEPub/META-INF/container.xml", [self applicationDocumentsDirectoryPath]];
  NSLog(@"containerPath: %@", containerPath);
	NSFileManager *fileManager = [[NSFileManager alloc] init];
	if ([fileManager fileExistsAtPath:containerPath]) {
    NSLog(@"valid epub - container.xml exist");
		CXMLDocument* manifestDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:containerPath] options:0 error:nil];
		CXMLNode *opfNode = [manifestDocument nodeForXPath:@"//@full-path[1]" error:nil];
    NSString *opfPath = [NSString stringWithFormat:@"%@/UnZippedEPub/%@", [self applicationDocumentsDirectoryPath], [opfNode stringValue]];
    NSLog(@"opfPath: %@", opfPath);
    self.opfPath = opfPath;
	} else {
    NSLog(@"invalid epub - container.xml not exist");
	}
}

- (void)parseOpf {
	CXMLDocument *opfDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:self.opfPath] options:0 error:nil];
	NSArray *itemElements = [opfDocument nodesForXPath:@"//opf:item" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]
                                               error:nil];
  NSString *ncxFileName = nil;
  NSMutableDictionary *itemsDictionary = [[NSMutableDictionary alloc] init];
	for (CXMLElement *element in itemElements) {
    NSString *ident = [[element attributeForName:@"id"] stringValue];
    NSString *href = [[element attributeForName:@"href"] stringValue];
		[itemsDictionary setValue:href forKey:ident];
    NSString *mediaType = [[element attributeForName:@"media-type"] stringValue];
    if([mediaType isEqualToString:@"application/xhtml+xml"] || [mediaType isEqualToString:@"application/x-dtbncx+xml"]) {
      ncxFileName = href;
    }
	}
  int lastSlashPosition = [self.opfPath rangeOfString:@"/" options:NSBackwardsSearch].location;
	NSString *basePath = [self.opfPath substringToIndex:(lastSlashPosition+1)];
  CXMLDocument *ncxDocument = [[CXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", basePath, ncxFileName]]
                                                                  options:0 error:nil];
  NSMutableDictionary *titlesDictionary = [[NSMutableDictionary alloc] init];
  for (CXMLElement *element in itemElements) {
    NSString *href = [[element attributeForName:@"href"] stringValue];
    NSString *xPath = [NSString stringWithFormat:@"//ncx:content[@src='%@']/../ncx:navLabel/ncx:text", href];
    NSArray *navPoints = [ncxDocument nodesForXPath:xPath namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.daisy.org/z3986/2005/ncx/" forKey:@"ncx"]
                                              error:nil];
    if ([navPoints count] != 0) {
      CXMLElement *titleElement = [navPoints objectAtIndex:0];
      [titlesDictionary setValue:[titleElement stringValue] forKey:href];
    }
  }
	NSArray *itemRefElements = [opfDocument nodesForXPath:@"//opf:itemref" namespaceMappings:[NSDictionary dictionaryWithObject:@"http://www.idpf.org/2007/opf" forKey:@"opf"]
                                                error:nil];
	NSMutableArray *chapters = [[NSMutableArray alloc] init];
	for (int count = 0; count < itemRefElements.count; count++) {
    CXMLElement *element = itemRefElements[count];
    NSString *idref = [[element attributeForName:@"idref"] stringValue];
    NSString *href = [itemsDictionary valueForKey:idref];
    NSString *chapterPath = [NSString stringWithFormat:@"%@%@", basePath, href];
    NSString *title = [titlesDictionary valueForKey:href];
    Chapter *chapter = [[Chapter alloc] initWithPath:chapterPath title:title chapterIndex:count];
		[chapters addObject:chapter];
	}
	self.chapters = [NSArray arrayWithArray:chapters];
}

@end
