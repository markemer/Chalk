//
//  CHConstantsProviderManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 03/04/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantsProviderManager.h"

#import "CHConstantsProvider.h"
#import "NSMutableArrayExtended.h"

@implementation CHConstantsProviderManager

@dynamic constantsProviders;

+(CHConstantsProviderManager*) sharedConstantsProviderManager
{
  static CHConstantsProviderManager* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      instance = [[CHConstantsProviderManager alloc] init];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sharedConstantsProviderManager

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->constantsProviders = [[NSMutableArray<CHConstantsProvider*> alloc] init];
  NSURL* url = [[NSBundle mainBundle] URLForResource:@"constants" withExtension:@"plist"];
  CHConstantsProvider* constantsProvider = [[[CHConstantsProvider alloc] initWithURL:url] autorelease];
  [self->constantsProviders safeAddObject:constantsProvider];
  return self;
}
//end init

-(void) dealloc
{
  [self->constantsProviders release];
  [super dealloc];
}
//end dealloc

-(NSArray<CHConstantsProvider*>*) constantsProviders
{
  NSArray* result = [[self->constantsProviders copy] autorelease];
  return result;
}
//end constantsProviders

-(void) addConstantsProvider:(CHConstantsProvider*)constantsProvider
{
  if (constantsProvider && ![self->constantsProviders containsObject:constantsProvider])
    [self->constantsProviders addObject:constantsProvider];
}
//end addConstantsProvider:

@end
