//
//  CHUnitManager.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUnitManager.h"

#import "CHUnit.h"
#import "CHUnitDescription.h"
#import "NSStringExtended.h"

@implementation CHUnitManager

+(CHUnitManager*) sharedUnitManager
{
  static CHUnitManager* instance = nil;
  if (!instance)
  {
    @synchronized(self)
    {
      instance = [[CHUnitManager alloc] init];
    }//end @synchronized(self)
  }//end if (!instance)
  return instance;
}
//end sharedUnitManager

-(instancetype) init
{
  if (!((self = [super init])))
    return nil;
  self->units = [[NSMutableDictionary<NSString*, CHUnit*> alloc] init];
  return self;
}
//end init

-(void) dealloc
{
  [self->units release];
  [super dealloc];
}
//end dealloc

-(CHUnit*) unitWithPlist:(id)plist
{
  CHUnit* result = nil;
  CHUnitDescription* unitDescription = [[[CHUnitDescription alloc] initWithPlist:plist] autorelease];
  NSString* uid = unitDescription.uid;
  if (![NSString isNilOrEmpty:uid])
  {
    @synchronized(self->units)
    {
      result = [self->units objectForKey:uid];
      if (!result)
      {
        result = [[[CHUnit alloc] initWithDescription:unitDescription] autorelease];
        if (result)
          [self->units setObject:result forKey:uid];
      }//end if (uid && !result)
    }//end @synchronized(self->units)
  }//end if (![NSString isNilOrEmpty:uid])
  return result;
}
//end unitWithPlist:

@end
