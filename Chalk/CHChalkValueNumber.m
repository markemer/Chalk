//
//  CHChalkValueNumber.m
//  Chalk
//
//  Created by Pierre Chatelier on 09/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueNumber.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"

@implementation CHChalkValueNumber

@dynamic sign;

+(BOOL) supportsSecureCoding {return YES;}

-(NSInteger) sign
{
  return 0;
}
//end sign

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorUnimplemented] context:context];
}
//end writeBodyToStream:context:options:

@end
