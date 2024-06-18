//
//  CHGenericTransformer.m
//  Chalk
//
//  Created by Pierre Chatelier on 11/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHGenericTransformer.h"

@implementation CHGenericTransformer

+(NSString*) name
{
  NSString* result = [self className];
  return result;
}
//end name

+(Class) transformedValueClass
{
  return [NSObject class];
}
//end transformedValueClass

+(BOOL) allowsReverseTransformation
{
  return YES;
}
//end allowsReverseTransformation

+(instancetype) transformerWithBlock:(id (^)(id))transformBlock reverse:(id (^)(id))reverseBlock
{
  return [[[[self class] alloc] initWithBlock:transformBlock reverse:reverseBlock] autorelease];
}
//end transformerWithBlock:reverse:

-(instancetype) initWithBlock:(id (^)(id))aTransformBlock reverse:(id (^)(id))aReverseBlock
{
  if (!((self = [super init])))
    return nil;
  self->transformBlock = [aTransformBlock copy];
  self->reverseTransformBlock = [aReverseBlock copy];
  return self;
}
//end initWithBlock:reverse:

-(void) dealloc
{
  [self->transformBlock release];
  [self->reverseTransformBlock release];
  [super dealloc];
}
//end dealloc

-(id) transformedValue:(id)value
{
  id result = !self->transformBlock ? value : self->transformBlock(value);
  return result;
}
//end transformedValue:

-(id) reverseTransformedValue:(id)value
{
  id result = !self->reverseTransformBlock ? value : self->reverseTransformBlock(value);
  return result;
}
//end reverseTransformedValue:

@end
