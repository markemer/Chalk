//
//  NSFileManagerExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "NSFileManagerExtended.h"

@implementation NSFileManager (Extended)

-(NSString*) localizedPath:(NSString*)path
{
  NSMutableArray* localizedPathComponents = [NSMutableArray array];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSArray* components = [path pathComponents];
  components = components ? components : [NSArray array];
  NSUInteger i = 0;
  for(i = 1 ; (i <= [components count]) ; ++i)
  {
    NSString* subPath = [NSString pathWithComponents:[components subarrayWithRange:NSMakeRange(0, i)]];
    [localizedPathComponents addObject:[fileManager displayNameAtPath:subPath]];
  }//end for each subPath
  return [NSString pathWithComponents:localizedPathComponents];
}
//end localizedPath:

-(NSString*) UTIFromPath:(NSString*)path
{
  NSString* result = nil;
  NSString* pathExtension = path.pathExtension;
  result = [(NSString*)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (CFStringRef)pathExtension, NULL) autorelease];
  return result;
};
//end UTIFromPath:

-(NSString*) getUnusedFilePathFromPrefix:(NSString*)filePrefix extension:(NSString*)extension folder:(NSString*)folder startSuffix:(NSUInteger)startSuffix
{
  NSString* result = nil;
  NSString* fileName = nil;
  NSString* filePath = nil;
  NSUInteger suffix = startSuffix;
  do
  {
    fileName = [NSString stringWithFormat:@"%@%@",
                 filePrefix,
                 !suffix ? @"" : [NSString stringWithFormat:@"-%lu", (unsigned long)suffix]];
    ++suffix;
    fileName = [fileName stringByAppendingPathExtension:extension];
    filePath = [folder stringByAppendingPathComponent:fileName];
  } while ((suffix != NSNotFound) && [self fileExistsAtPath:filePath]);
  result = filePath;
  return result;
}
//end getUnusedFilePathFromPrefix:folder:startSuffix:

@end
