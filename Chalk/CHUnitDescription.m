//
//  CHUnitDescription.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUnitDescription.h"

#import "CHUnitElementDescription.h"
#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"

@implementation CHUnitDescription

@synthesize uid;
@synthesize unitElementsDescriptions;

-(instancetype) initWithPlist:(id)plist
{
  NSDictionary* plistAsDict = [plist dynamicCastToClass:[NSDictionary class]];
  if (!plistAsDict)
  {
    [self release];
    return nil;
  }//end if (!plistAsDict)
  
  if (!((self = [super init])))
    return nil;
  
  NSArray* components = [[plistAsDict objectForKey:@"unit_components"] dynamicCastToClass:[NSArray class]];
  NSMutableArray* unitElementDescriptionsOrdered = [NSMutableArray array];
  NSMutableDictionary* unitElementDescriptionsByName = [NSMutableDictionary dictionary];
  for(id componentPlist in components)
  {
    CHUnitElementDescription* unitElementDescription = [[[CHUnitElementDescription alloc] initWithPlist:componentPlist] autorelease];
    if (unitElementDescription)
    {
      CHUnitElementDescription* existingUnitElementDescription = [unitElementDescriptionsByName objectForKey:unitElementDescription.name];
      if (!existingUnitElementDescription)
      {
        [unitElementDescriptionsByName setObject:unitElementDescription forKey:unitElementDescription.name];
        [unitElementDescriptionsOrdered addObject:unitElementDescription];
      }//end if (!existingUnitElementDescription)
      else
        [existingUnitElementDescription addPower:unitElementDescription.power];
    }//end if (unitElementDescription)
  }//end for each componentPlist
  self->unitElementsDescriptions = [unitElementDescriptionsOrdered copy];
  
  NSMutableArray* uids = [NSMutableArray array];
  for(CHUnitElementDescription* unitElementDescription in self->unitElementsDescriptions)
    [uids safeAddObject:unitElementDescription.uid];
  self->uid = [[uids componentsJoinedByString:@"*"] copy];
  
  return self;
}
//end initWithPlist:

-(void) dealloc
{
  [self->uid release];
  [self->unitElementsDescriptions release];
  [super dealloc];
}
//end dealloc

@end
