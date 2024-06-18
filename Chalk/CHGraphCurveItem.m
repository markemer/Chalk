//
//  CHGraphCurveItem.m
//  Chalk
//
//  Created by Pierre Chatelier on 15/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGraphCurveItem.h"

#import "CHGraphCurve.h"
#import "CHParserNode.h"
#import "NSObjectExtended.h"

NSString* CHGraphCurveItemNameKey = @"name";
NSString* CHGraphCurveItemCurveKey = @"curve";
NSString* CHGraphCurveItemIsDynamicKey = @"isDynamic";
NSString* CHGraphCurveItemCurveThicknessKey = @"curveThickness";
NSString* CHGraphCurveItemCurveColorKey = @"curveColor";
NSString* CHGraphCurveItemCurveInteriorColorKey = @"curveInteriorColor";
NSString* CHGraphCurveItemCurveUncertaintyVisibleKey = @"curveUncertaintyVisible";
NSString* CHGraphCurveItemCurveUncertaintyColorKey = @"curveUncertaintyColor";
NSString* CHGraphCurveItemCurveUncertaintyNaNVisibleKey = @"curveUncertaintyNaNVisible";
NSString* CHGraphCurveItemCurveUncertaintyNaNColorKey = @"curveUncertaintyNaNColor";
NSString* CHGraphCurveItemPredicateColorFalseKey = @"predicateColorFalse";
NSString* CHGraphCurveItemPredicateColorTrueKey = @"predicateColorTrue";

NSString* CHGraphCurveItemIsUpdatingKey = @"isUpdating";

NSString* CHGraphCurveItemDidInvalidateNotification = @"CHGraphCurveItemDidInvalidateNotification";

@implementation CHGraphCurveItem

@synthesize enabled;
@synthesize name;
@synthesize curveThickness;
@synthesize curveColor;
@synthesize curveInteriorColor;
@synthesize curveUncertaintyVisible;
@synthesize curveUncertaintyColor;
@synthesize curveUncertaintyNaNVisible;
@synthesize curveUncertaintyNaNColor;
@synthesize predicateColorFalse;
@synthesize predicateColorTrue;
@synthesize curve;
@synthesize isUpdating;
@dynamic    isPredicate;

@dynamic hasCircularDependency;
@dynamic identifier;
@dynamic isDynamic;
@dynamic dependingIdentifiers;

+(void) initialize
{
  [self exposeBinding:NSEnabledBinding];
  [self exposeBinding:CHGraphCurveItemNameKey];
  [self exposeBinding:CHGraphCurveItemCurveKey];
  [self exposeBinding:CHGraphCurveItemIsDynamicKey];
  [self exposeBinding:CHGraphCurveItemCurveThicknessKey];
  [self exposeBinding:CHGraphCurveItemCurveColorKey];
  [self exposeBinding:CHGraphCurveItemCurveInteriorColorKey];
  [self exposeBinding:CHGraphCurveItemCurveUncertaintyVisibleKey];
  [self exposeBinding:CHGraphCurveItemCurveUncertaintyColorKey];
  [self exposeBinding:CHGraphCurveItemCurveUncertaintyNaNVisibleKey];
  [self exposeBinding:CHGraphCurveItemCurveUncertaintyNaNColorKey];
  [self exposeBinding:CHGraphCurveItemPredicateColorFalseKey];
  [self exposeBinding:CHGraphCurveItemPredicateColorTrueKey];
  [self exposeBinding:CHGraphCurveItemIsUpdatingKey];
}
//end initialize

+(NSSet*) keyPathsForValuesAffectingIsPredicate
{
  NSSet* result = [NSSet setWithObjects:CHGraphCurveItemIsUpdatingKey, nil];
  return result;
}
//end keyPathsForValuesAffectingIsPredicate

+(NSColor*) defaultCurveColor
{
  return [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:1];
}
//end defaultCurveColor

+(NSColor*) defaultCurveInteriorColor
{
  return nil;
}
//end defaultCurveInteriorColor

+(NSColor*) defaultCurveUncertaintyColor
{
  return [NSColor colorWithCalibratedRed:.66 green:.66 blue:.66 alpha:.75];
}
//end defaultCurveUncertaintyColor

+(NSColor*) defaultCurveUncertaintyNaNColor
{
  return [NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:.5];
}
//end defaultCurveUncertaintyNaNColor

+(NSColor*) defaultPredicateFalseColor
{
  return [NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.5];
}
//end defaultPredicateFalseColor

+(NSColor*) defaultPredicateTrueColor
{
  return [NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:.5];
}
//end defaultPredicateTrueColor

-(instancetype) init
{
  return [self initWithCurve:nil];
}
//end init

-(instancetype) initWithCurve:(CHGraphCurve*)aCurve
{
  if (!((self = [super init])))
    return nil;
  self->curve = [aCurve retain];
  self->curveThickness = 1U;
  self->curveColor = [[CHGraphCurveItem defaultCurveColor] copy];
  self->curveInteriorColor = [[CHGraphCurveItem defaultCurveInteriorColor] copy];
  self->curveUncertaintyVisible = YES;
  self->curveUncertaintyColor = [[CHGraphCurveItem defaultCurveUncertaintyColor] copy];
  self->curveUncertaintyNaNVisible = YES;
  self->curveUncertaintyNaNColor = [[CHGraphCurveItem defaultCurveUncertaintyNaNColor] copy];
  self->predicateColorFalse = [[CHGraphCurveItem defaultPredicateFalseColor] copy];
  self->predicateColorTrue = [[CHGraphCurveItem defaultPredicateTrueColor] copy];
  return self;
}
//end init

-(void) dealloc
{
  [self->name release];
  [self->curve release];
  [self->curveColor release];
  self->curveColor = nil;
  [self->curveInteriorColor release];
  self->curveInteriorColor = nil;
  [self->curveUncertaintyColor release];
  self->curveUncertaintyColor = nil;
  [self->curveUncertaintyNaNColor release];
  self->curveUncertaintyNaNColor = nil;
  [self->predicateColorFalse release];
  self->predicateColorFalse = nil;
  [self->predicateColorTrue release];
  self->predicateColorTrue = nil;
  [super dealloc];
}
//end dealloc

-(id) copyWithZone:(NSZone*)zone
{
  CHGraphCurveItem* result = [[CHGraphCurveItem alloc] initWithCurve:self->curve];
  result.name = self.name;
  result.curveThickness = self.curveThickness;
  result.curveColor = self.curveColor;
  result.curveInteriorColor = self.curveInteriorColor;
  result.curveUncertaintyVisible = self.curveUncertaintyVisible;
  result.curveUncertaintyColor = self.curveUncertaintyColor;
  result.curveUncertaintyNaNVisible = self.curveUncertaintyNaNVisible;
  result.curveUncertaintyNaNColor = self.curveUncertaintyNaNColor;
  result.predicateColorFalse = self.predicateColorFalse;
  result.predicateColorTrue = self.predicateColorTrue;
  result.enabled = self.enabled;
  result.delegate = self.delegate;
  return result;
}
//end copyWithZone:

-(void) setEnabled:(BOOL)value
{
  if (value != self->enabled)
  {
    [self willChangeValueForKey:NSEnabledBinding];
    self->enabled = value;
    [self didChangeValueForKey:NSEnabledBinding];
    [self propagateValue:@(self->enabled) forBinding:NSEnabledBinding];
  }//end if (value != self->enabled)
}
//end setEnabled:

-(void) setCurveThickness:(NSUInteger)value
{
  if (value != self->curveThickness)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveThicknessKey];
    self->curveThickness = value;
    [self didChangeValueForKey:CHGraphCurveItemCurveThicknessKey];
    [self propagateValue:@(self->curveThickness) forBinding:CHGraphCurveItemCurveThicknessKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveThickness)
}
//end setCurveThickness:

-(void) setCurveColor:(NSColor*)value
{
  if (value != self->curveColor)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveColorKey];
    [self->curveColor release];
    self->curveColor = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemCurveColorKey];
    [self propagateValue:self->curveColor forBinding:CHGraphCurveItemCurveColorKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveColor)
}
//end setCurveColor:

-(void) setCurveInteriorColor:(NSColor*)value
{
  if (value != self->curveInteriorColor)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveInteriorColorKey];
    [self->curveInteriorColor release];
    self->curveInteriorColor = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemCurveInteriorColorKey];
    [self propagateValue:self->curveInteriorColor forBinding:CHGraphCurveItemCurveInteriorColorKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveColor)
}
//end setCurveInteriorColor:

-(void) setCurveUncertaintyVisible:(BOOL)value
{
  if (value != self->curveUncertaintyVisible)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveUncertaintyVisibleKey];
    self->curveUncertaintyVisible = value;
    [self didChangeValueForKey:CHGraphCurveItemCurveUncertaintyVisibleKey];
    [self propagateValue:@(self->curveUncertaintyVisible) forBinding:CHGraphCurveItemCurveUncertaintyVisibleKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveUncertaintyVisible)
}
//end setCurveUncertaintyVisible:

-(void) setCurveUncertaintyColor:(NSColor*)value
{
  if (value != self->curveUncertaintyColor)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveUncertaintyColorKey];
    [self->curveUncertaintyColor release];
    self->curveUncertaintyColor = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemCurveUncertaintyColorKey];
    [self propagateValue:self->curveUncertaintyColor forBinding:CHGraphCurveItemCurveUncertaintyColorKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveUncertaintyColor)
}
//end setCurveUncertaintyColor:

-(void) setCurveUncertaintyNaNVisible:(BOOL)value
{
  if (value != self->curveUncertaintyNaNVisible)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveUncertaintyNaNVisibleKey];
    self->curveUncertaintyNaNVisible = value;
    [self didChangeValueForKey:CHGraphCurveItemCurveUncertaintyNaNVisibleKey];
    [self propagateValue:@(self->curveUncertaintyNaNVisible) forBinding:CHGraphCurveItemCurveUncertaintyNaNVisibleKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveUncertaintyNaNVisible)
}
//end setCurveUncertaintyNaNVisible:

-(void) setCurveUncertaintyNaNColor:(NSColor*)value
{
  if (value != self->curveUncertaintyNaNColor)
  {
    [self willChangeValueForKey:CHGraphCurveItemCurveUncertaintyNaNColorKey];
    [self->curveUncertaintyNaNColor release];
    self->curveUncertaintyNaNColor = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemCurveUncertaintyNaNColorKey];
    [self propagateValue:self->curveUncertaintyNaNColor forBinding:CHGraphCurveItemCurveUncertaintyNaNColorKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->curveUncertaintyNaNColor)
}
//end setCurveUncertaintyNaNColor:

-(void) setPredicateColorFalse:(NSColor*)value
{
  if (value != self->predicateColorFalse)
  {
    [self willChangeValueForKey:CHGraphCurveItemPredicateColorFalseKey];
    [self->predicateColorFalse release];
    self->predicateColorFalse = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemPredicateColorFalseKey];
    [self propagateValue:self->predicateColorFalse forBinding:CHGraphCurveItemPredicateColorFalseKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->predicateColorFalse)
}
//end setPredicateColorFalse:

-(void) setPredicateColorTrue:(NSColor*)value
{
  if (value != self->predicateColorTrue)
  {
    [self willChangeValueForKey:CHGraphCurveItemPredicateColorTrueKey];
    [self->predicateColorTrue release];
    self->predicateColorTrue = [value copy];
    [self didChangeValueForKey:CHGraphCurveItemPredicateColorTrueKey];
    [self propagateValue:self->predicateColorTrue forBinding:CHGraphCurveItemPredicateColorTrueKey];
    if ([self.delegate respondsToSelector:@selector(graphCurveItemDidInvalidate:)])
      [self.delegate graphCurveItemDidInvalidate:[NSNotification notificationWithName:CHGraphCurveItemDidInvalidateNotification object:self]];
  }//end if (value != self->predicateColorTrue)
}
//end setPredicateColorTrue:

-(BOOL) isPredicate
{
  BOOL result = self->curve.chalkParserNode.isPredicate;
  return result;
}
//end isPredicate

#pragma mark CHChalkIdentifierDependent
-(BOOL) isDynamic
{
  BOOL result = self->curve.isDynamic;
  return result;
}
//end isDynamic

-(BOOL) hasCircularDependency
{
  BOOL result = self->curve.hasCircularDependency;
  return result;
}
//end hasCircularDependency

-(void) setHasCircularDependency:(BOOL)value
{
  self->curve.hasCircularDependency = value;
}
//end setHasCircularDependency:

-(CHChalkIdentifier*) identifier
{
  CHChalkIdentifier* result = self->curve.identifier;
  return result;
}
//end identifier

-(NSSet*) dependingIdentifiers
{
  NSSet* result = self->curve.dependingIdentifiers;
  return result;
}
//end dependingIdentifiers

-(void) refreshIdentifierDependencies
{
  [self->curve refreshIdentifierDependencies];
}
//end refreshIdentifierDependencies

-(BOOL) hasIdentifierDependency:(CHChalkIdentifier*)aIdentifier
{
  BOOL result = [self->curve hasIdentifierDependency:aIdentifier];
  return result;
}
//end hasIdentifierDependency:

-(BOOL) hasIdentifierDependencyByTokens:(NSArray*)tokens
{
  BOOL result = [self->curve hasIdentifierDependencyByTokens:tokens];
  return result;
}
//end hasIdentifierDependencyByToken:

@end
