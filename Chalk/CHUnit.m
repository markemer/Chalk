//
//  CHUnit.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUnit.h"

#import "CHUnitDescription.h"
#import "CHUnitElement.h"
#import "CHUnitElementDescription.h"
#import "NSAttributedStringExtended.h"
#import "NSMutableArrayExtended.h"

@implementation CHUnit

@synthesize unitElements;
@dynamic richDescription;

-(instancetype) initWithDescription:(CHUnitDescription*)unitDescription
{
  if (!unitDescription)
  {
    [self release];
    return nil;
  }//end if (!unitDescription)
  
  if (!((self = [super init])))
    return nil;
  
  NSArray<CHUnitElementDescription*>* unitElementsDescriptions = unitDescription.unitElementsDescriptions;
  NSMutableArray* _unitElements = [NSMutableArray arrayWithCapacity:unitElementsDescriptions.count];
  for(CHUnitElementDescription* unitElementDescription in unitElementsDescriptions)
  {
    CHUnitElement* unitElement = [[[CHUnitElement alloc] initWithDescription:unitElementDescription] autorelease];
    [_unitElements safeAddObject:unitElement];
  }//end for each unitElementDescription
  self->unitElements = [_unitElements copy];
 
  return self;
}
//end initWithDescription:

-(void) dealloc
{
  [self->unitElements release];
  [self->richDescription_cached release];
  [super dealloc];
}
//end dealloc

-(NSAttributedString*) richDescription
{
  NSAttributedString* result = [[self->richDescription_cached copy] autorelease];
  if (!result)
  {
    NSMutableAttributedString* unitBuilder = [[[NSMutableAttributedString alloc] init] autorelease];
    NSMutableAttributedString* unitElementBuilder = [[[NSMutableAttributedString alloc] init] autorelease];
    NSAttributedString* unitSeparator = [[[NSAttributedString alloc] initWithString:@"."] autorelease];
    CGFloat systemFontSize = [NSFont systemFontSize];
    NSFont* defaultFont = [NSFont systemFontOfSize:systemFontSize];
    NSDictionary* superScriptAttributes = @{
      NSFontAttributeName:[NSFont systemFontOfSize:2*systemFontSize/3],
      NSBaselineOffsetAttributeName:@(defaultFont.xHeight)};
    for(CHUnitElement* unitElement in self->unitElements)
    {
      [unitElementBuilder deleteCharactersInRange:unitElementBuilder.range];
      [unitElementBuilder appendAttributedString:[[[NSAttributedString alloc] initWithString:unitElement.name attributes:nil] autorelease]];
      [unitElementBuilder appendAttributedString:[[[NSAttributedString alloc] initWithString:unitElement.powerAsString attributes:superScriptAttributes] autorelease]];
      if (unitElementBuilder.length != 0)
      {
        if (unitBuilder.length != 0)
          [unitBuilder appendAttributedString:unitSeparator];
        [unitBuilder appendAttributedString:unitElementBuilder];
      }//end if (unitElementBuilder.length != 0)
    }//end for each unitElement
    self->richDescription_cached = [unitBuilder copy];
    result = [[self->richDescription_cached copy] autorelease];
  }//end if (!result)
  return result;
}
//end richDescription

@end
