//
//  CHUserFunction.m
//  Chalk
//
//  Created by Pierre Chatelier on 01/05/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHUserFunctionEntity.h"

#import "CHComputedValueEntity.h"
#import "NSObjectExtended.h"
#import "NSStringExtended.h"

@implementation CHUserFunctionEntity

@dynamic identifierName;
@dynamic inputRawString;
@dynamic argumentNames;

+(NSString*) entityName {return @"UserFunction";}

-(void) setInputRawString:(NSString*)value
{
  if (![NSString string:value equals:self.inputRawString])
  {
    [self willChangeValueForKey:@"inputRawString"];
    [self setPrimitiveValue:value forKey:@"inputRawString"];
    [self didChangeValueForKey:@"inputRawString"];
  }//end if (![NSString string:value equals:self.inputRawString])
}
//end setInputRawString:

@end
