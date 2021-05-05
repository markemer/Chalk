//
//  NSWorkspaceExtended.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/07/05.
//  Copyright 2005-2014 Pierre Chatelier. All rights reserved.
//

//this file is an extension of the NSWorkspace class

#import "NSWorkspaceExtended.h"

#import "NSObjectExtended.h"

@implementation NSWorkspace (Extended)

-(NSString*) applicationName
{
  NSString* result = nil;
  CFDictionaryRef bundleInfoDict = CFBundleGetInfoDictionary(CFBundleGetMainBundle());
  result = (NSString*) CFDictionaryGetValue(bundleInfoDict, kCFBundleExecutableKey);
  return result;
}
//end applicationName

-(NSString*) applicationVersion
{
  NSString* result = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
  return result;
}
//end applicationVersion

-(NSString*) applicationBundleIdentifier
{
  NSString* result = nil;
  CFDictionaryRef bundleInfoDict = CFBundleGetInfoDictionary(CFBundleGetMainBundle());
  result = (NSString*) CFDictionaryGetValue(bundleInfoDict, kCFBundleIdentifierKey);
  return result;
}
//end applicationName

-(NSString*) temporaryDirectory
{
  NSString* thisVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey];
  if (!thisVersion)
    thisVersion = @"";
  NSArray* components = [thisVersion componentsSeparatedByString:@" "];
  if (components && [components count])
    thisVersion = [components objectAtIndex:0];
  NSString* temporaryPath =
    [NSTemporaryDirectory() stringByAppendingPathComponent:
      [NSString stringWithFormat:@"%@-%@", [self applicationName], thisVersion]];
  NSFileManager* fileManager = [NSFileManager defaultManager];
  BOOL isDirectory = NO;
  BOOL exists = [fileManager fileExistsAtPath:temporaryPath isDirectory:&isDirectory];
  if (exists && !isDirectory)
  {
    [fileManager removeItemAtPath:temporaryPath error:0];
    exists = NO;
  }
  if (!exists)
    [fileManager createDirectoryAtPath:temporaryPath withIntermediateDirectories:YES attributes:nil error:0];
  return temporaryPath;
}
//end temporaryDirectory

-(NSString*) getBestStandardPath:(NSSearchPathDirectory)searchPathDirectory domain:(NSSearchPathDomainMask)domain defaultValue:(NSString*)defaultValue
{
  __block NSString* result = nil;
  NSArray* candidates = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domain, YES);
  NSFileManager* fileManager = [NSFileManager defaultManager];
  [candidates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSString* candidate = [obj dynamicCastToClass:[NSString class]];
    BOOL isDirectory = YES;
    if (candidate && [fileManager fileExistsAtPath:candidate isDirectory:&isDirectory] && isDirectory)
    {
      result = candidate;
      *stop = YES;
    }//end if (candidate && [fileManager fileExistsAtPath:candidate isDirectory:&isDirectory] && isDirectory)
  }];
  if (!result)
    result = defaultValue;
  return result;
}
//end getBestStandardPath:domain:defaultValue:

-(NSURL*) getBestStandardURL:(NSSearchPathDirectory)searchPathDirectory domain:(NSSearchPathDomainMask)domain defaultValue:(NSURL*)defaultValue
{
  __block NSURL* result = nil;
  NSFileManager* fileManager = [NSFileManager defaultManager];
  NSArray<NSURL*>* candidates = [fileManager URLsForDirectory:searchPathDirectory inDomains:domain];
  [candidates enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    NSURL* candidate = [obj dynamicCastToClass:[NSURL class]];
    NSString* filePath = [candidate path];
    BOOL isDirectory = YES;
    if (candidate && (![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] || isDirectory))
    {
      result = candidate;
      *stop = YES;
    }//end if (candidate && (![fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] || isDirectory))
  }];
  if (!result)
    result = defaultValue;
  return result;
}
//end getBestStandardURL:domain:defaultValue:

@end
