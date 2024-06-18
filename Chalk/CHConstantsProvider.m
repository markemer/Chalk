//
//  CHConstantsProvider.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantsProvider.h"

#import "CHConstantDescription.h"
#import "CHUtils.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHConstantsProvider

@synthesize name;
@dynamic    nameNotEmpty;
@synthesize author;
@synthesize version;
@synthesize comments;
@synthesize constantDescriptions;

-(instancetype) initWithURL:(NSURL*)url
{
  NSData* data = !url ? nil : [NSData dataWithContentsOfURL:url];
  NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
  NSError* error = nil;
  id plist = !data ? nil : [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:&format error:&error];
  if (!((self = [self initWithPlist:plist])))
    return nil;
  return self;
}
//end initWithURL:

-(instancetype) initWithPlist:(id)plist
{
  NSDictionary* plistAsDict = [plist dynamicCastToClass:[NSDictionary class]];
  NSDictionary* informationPlist = [[plistAsDict objectForKey:@"information"] dynamicCastToClass:[NSDictionary class]];
  NSDictionary* constantsPlist = [[plistAsDict objectForKey:@"constants"] dynamicCastToClass:[NSDictionary class]];
  if (!constantsPlist)
  {
    [self release];
    return nil;
  }//end if (!constantsPlist)
  if (!((self = [super init])))
    return nil;
  self.name = [[[[informationPlist objectForKey:@"name"] dynamicCastToClass:[NSString class]] copy] autorelease];
  self.author = [[[[informationPlist objectForKey:@"author"] dynamicCastToClass:[NSString class]] copy] autorelease];
  self.version = [[[[informationPlist objectForKey:@"version"] dynamicCastToClass:[NSString class]] copy] autorelease];
  self.comments = [[[[informationPlist objectForKey:@"comments"] dynamicCastToClass:[NSString class]] copy] autorelease];
  
  NSMutableDictionary* usedUids = [NSMutableDictionary dictionary];
  NSMutableDictionary* usedNames = [NSMutableDictionary dictionary];
  NSMutableDictionary* usedShortnames = [NSMutableDictionary dictionary];
  
  self->constantDescriptions = [[NSMutableArray alloc] init];
  NSEnumerator* keyEnumerator = [constantsPlist keyEnumerator];
  id key = nil;
  while((key = [keyEnumerator nextObject]))
  {
    NSString* keyAsString = [key dynamicCastToClass:[NSString class]];
    id value = [constantsPlist objectForKey:key];
    CHConstantDescription* constantDescription = !keyAsString || !value ? nil :
      [[CHConstantDescription alloc] initWithUid:keyAsString plist:value];
    if (constantDescription)
    {
      BOOL isValidUID = ![NSString isNilOrEmpty:constantDescription.uid] && ![usedUids objectForKey:constantDescription.uid];
      BOOL isValidName = ![NSString isNilOrEmpty:constantDescription.name] && ![usedNames objectForKey:constantDescription.name];
      BOOL isValidShortName = [NSString isNilOrEmpty:constantDescription.shortName] || ![usedShortnames objectForKey:constantDescription.shortName];
      if (!isValidUID)
        DebugLog(0, @"duplicate constant uid %@", constantDescription.uid);
      if (!isValidName)
        DebugLog(0, @"duplicate constant name %@", constantDescription.name);
      if (!isValidShortName)
        DebugLog(0, @"duplicate constant shortName %@", constantDescription.shortName);
      BOOL canAddConstant = isValidUID && isValidName && isValidShortName;
      if (canAddConstant)
        [self->constantDescriptions addObject:constantDescription];
    }//end if (constantDescription)
    [constantDescription release];
  }//end for each key
  return self;
}
//end initWithPlist:

-(void) dealloc
{
  self.name = nil;
  self.author = nil;
  self.version = nil;
  self.comments = nil;
  [self->constantDescriptions release];
  [super dealloc];
}
//end dealloc

-(NSString*) nameNotEmpty
{
  NSString* result = self.name;
  if ([NSString isNilOrEmpty:result])
    result = NSLocalizedString(@"Untitled", "");
  return result;
}
//end nameNotEmpty

@end
