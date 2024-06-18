//
//  CHComputedValueEntity.m
//  Chalk
//
//  Created by Pierre Chatelier on 12/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHComputedValueEntity.h"

#import "CHChalkValue.h"
#import "NSObjectExtended.h"

@implementation CHComputedValueEntity

@dynamic data;
@dynamic chalkValue;

+(NSString*) entityName {return @"ComputedValue";}

-(void) dealloc
{
  [self->chalkValue release];
  [super dealloc];
}
//end dealloc

-(void) setData:(NSData*)value
{
  if (value != self.data)
  {
    [self willChangeValueForKey:@"data"];
    [self setPrimitiveValue:value forKey:@"data"];
    [self->chalkValue release];
    self->chalkValue = nil;
    [self didChangeValueForKey:@"data"];
  }//end if (value != self.data)
}
//end setData:

-(CHChalkValue*) chalkValue
{
  CHChalkValue* result = nil;
  [self willAccessValueForKey:@"chalkValue"];
  if (self->chalkValue)
    result = [[self->chalkValue retain] autorelease];
  else//if (!self->chalkValue)
  {
    NSData* data = self.data;
    self->chalkValue = !data ? nil : [[[NSKeyedUnarchiver unarchiveObjectWithData:data] dynamicCastToClass:[CHChalkValue class]] retain];
    result = [[self->chalkValue retain] autorelease];
  }//end if (!self->chalkValue)
  [self didAccessValueForKey:@"chalkValue"];
  return result;
}
//end chalkValue

-(void) setChalkValue:(CHChalkValue*)value
{
  if (value != self->chalkValue)
  {
    [self willChangeValueForKey:@"chalkValue"];
    [self->chalkValue release];
    self->chalkValue = [value retain];
    self.data = !self->chalkValue ? nil : [NSKeyedArchiver archivedDataWithRootObject:self->chalkValue];
    [self didChangeValueForKey:@"chalkValue"];
  }//end if (!self->chalkValue)
}
//end chalkValue

@end
