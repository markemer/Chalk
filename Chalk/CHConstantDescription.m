//
//  CHConstantDescription.m
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import "CHConstantDescription.h"

#import "CHChalkUtils.h"
#import "CHConstantSymbolManager.h"
#import "CHUnit.h"
#import "CHUnitManager.h"
#import "CHUtils.h"

#import "NSMutableArrayExtended.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHConstantDescription

@synthesize uid;
@synthesize name;
@synthesize shortName;
@synthesize value;
@synthesize uncertainty;
@synthesize description;
@synthesize texSymbol;
@synthesize categories;
@synthesize commonUnits;
@dynamic commonUnitsRichDescriptions;

-(instancetype) initWithUid:(NSString*)aUid plist:(id)plist
{
  NSDictionary* plistAsDict = [plist dynamicCastToClass:[NSDictionary class]];
  if (!aUid || !plistAsDict)
  {
    [self release];
    return nil;
  }//end if (!aUid || !plistAsDict)
  if (!((self = [super init])))
    return nil;
    
  self->uid = [aUid copy];
  self->name = [[[plistAsDict objectForKey:@"name"] dynamicCastToClass:[NSString class]] copy];
  self->shortName = [[[plistAsDict objectForKey:@"shortName"] dynamicCastToClass:[NSString class]] copy];
  if ([NSString isNilOrEmpty:self->shortName])
  {
    [self->shortName release];
    self->shortName = [[self->name stringByReplacingOccurrencesOfRegex:@"\\s+" withString:@"_"] copy];
  }//end if ([NSString isNilOrEmpty:self->shortName])
  self->value = [[[plistAsDict objectForKey:@"value"] dynamicCastToClass:[NSString class]] copy];
  self->uncertainty = [[[plistAsDict objectForKey:@"uncertainty"] dynamicCastToClass:[NSString class]] copy];
  self->description = [[[plistAsDict objectForKey:@"description"] dynamicCastToClass:[NSString class]] copy];
  NSDictionary* symbol = [[plistAsDict objectForKey:@"symbol"] dynamicCastToClass:[NSDictionary class]];
  self->texSymbol = [[[symbol objectForKey:@"tex"] dynamicCastToClass:[NSString class]] copy];
  NSArray* commonUnitsDescriptions = [[plistAsDict objectForKey:@"common_units"] dynamicCastToClass:[NSArray class]];
  NSMutableArray* currentCommonUnits = [NSMutableArray arrayWithCapacity:commonUnitsDescriptions.count];
  for(id unitDescription in commonUnitsDescriptions)
  {
    CHUnit* unit = [[CHUnitManager sharedUnitManager] unitWithPlist:unitDescription];
    [currentCommonUnits safeAddObject:unit];
  }//end for each unitDescription
  self->commonUnits = !currentCommonUnits ? nil : [currentCommonUnits copy];
  NSArray* categoriesAsObjects = [[plistAsDict objectForKey:@"categories"] dynamicCastToClass:[NSArray class]];
  NSMutableArray* _categories = [NSMutableArray arrayWithCapacity:[categoriesAsObjects count]];
  for(id category in categoriesAsObjects)
    [_categories safeAddObject:[category dynamicCastToClass:[NSString class]]];
  self->categories = [_categories copy];

  BOOL error = [NSString isNilOrEmpty:self->uid] || [NSString isNilOrEmpty:self->name] || [NSString isNilOrEmpty:self->value];
  if (!error)
  {
    mpfr_t value;
    mpfr_init2(value, MPFR_PREC_MIN);
    const char* valueUTF8 = self->value.UTF8String;
    const char* uncertaintyUTF8 = self->uncertainty.UTF8String;
    char* endptr = 0;
    if (valueUTF8)
    {
      mpfr_strtofr(value, valueUTF8, &endptr, 10, MPFR_RNDN);
      error |= endptr && *endptr;
    }//end if (valueUTF8)
    if (error)
      DebugLog(0, @"Invalid constant <%@> <%@> value %s at %s\n", self->uid, self->name, valueUTF8, endptr);
    else//if (!error)
    {
      if (uncertaintyUTF8)
      {
        mpfr_strtofr(value, uncertaintyUTF8, &endptr, 10, MPFR_RNDN);
        error |= endptr && *endptr;
      }//end if (uncertaintyUTF8)
      if (error)
        DebugLog(0, @"Invalid constant <%@> <%@> uncertainty %s at %s\n", self->uid, self->name, uncertaintyUTF8, endptr);
    }//end if (!error)
    mpfr_clear(value);
  }//end if (!error)
  if (error)
  {
    [self release];
    return nil;
  }//end if (error)
 
  return self;
}
//end initWithUid:plist:

-(instancetype) initWithPlistValueDescription:(id)plist
{
  NSDictionary* plistAsDict = [plist dynamicCastToClass:[NSDictionary class]];
  if (!plistAsDict)
  {
    [self release];
    return nil;
  }//end if (!plistAsDict)
  if (!((self = [super init])))
    return nil;
    
  self->uid = [[[plistAsDict objectForKey:@"uid"] dynamicCastToClass:[NSString class]] copy];
  self->name = [[[plistAsDict objectForKey:@"name"] dynamicCastToClass:[NSString class]] copy];
  self->shortName = [[[plistAsDict objectForKey:@"shortName"] dynamicCastToClass:[NSString class]] copy];
  self->value = [[[plistAsDict objectForKey:@"value"] dynamicCastToClass:[NSString class]] copy];
  self->uncertainty = [[[plistAsDict objectForKey:@"uncertainty"] dynamicCastToClass:[NSString class]] copy];
  self->texSymbol = [[[plistAsDict objectForKey:@"texSymbol"] dynamicCastToClass:[NSString class]] copy];
  
  BOOL error = [NSString isNilOrEmpty:self->uid] || [NSString isNilOrEmpty:self->name] || [NSString isNilOrEmpty:self->value];
  if (error)
  {
    [self release];
    return nil;
  }//end if (error)

  return self;
}
//end initWithPlistValueDescription:

-(void) dealloc
{
  [self->uid release];
  [self->name release];
  [self->shortName release];
  [self->value release];
  [self->uncertainty release];
  [self->description release];
  [self->texSymbol release];
  [self->categories release];
  [self->commonUnits release];
  [self->commonUnitsRichDescriptions_cached release];
  [super dealloc];
}
//end dealloc

-(NSArray<NSAttributedString*>*) commonUnitsRichDescriptions
{
  NSArray<NSAttributedString*>* result = [[self->commonUnitsRichDescriptions_cached copy] autorelease];
  if (!result)
  {
    NSMutableArray<NSAttributedString*>* commonUnitsRichDescriptions = [NSMutableArray arrayWithCapacity:self->commonUnits.count];
    for(CHUnit* unit in self->commonUnits)
      [commonUnitsRichDescriptions safeAddObject:unit.richDescription];
    [self->commonUnitsRichDescriptions_cached release];
    self->commonUnitsRichDescriptions_cached = [commonUnitsRichDescriptions copy];
    result = [[self->commonUnitsRichDescriptions_cached copy] autorelease];
  }//end if (!result)
  return result;
}
//end commonUnitsRichDescriptions

-(NSString*) stringValueDescription
{
  NSString* result = nil;
  NSString* value = self.value;
  NSString* uncertainty = self.uncertainty;
  result =
    [NSString isNilOrEmpty:value] ? nil :
    [NSString isNilOrEmpty:uncertainty] ? value :
    [NSString stringWithFormat:@"%@%@%@", value, NSSTRING_PLUSMINUS, uncertainty];
  return result;
}
//end stringValueDescription

-(id) plistValueDescription
{
  id result = @{
    @"uid":!self->uid ? @"" : [[self->uid copy] autorelease],
    @"name":!self->name ? @"" : [[self->name copy] autorelease],
    @"shortName":!self->shortName ? @"" : [[self->shortName copy] autorelease],
    @"value":!self->value ? @"" : [[self->value copy] autorelease],
    @"uncertainty":!self->uncertainty ? @"" : [[self->uncertainty copy] autorelease],
    @"texSymbol":!self->texSymbol ? @"" : [[self->texSymbol copy] autorelease],
  };
  return result;
}
//end plistValueDescription

@end
