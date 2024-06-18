//
//  CHParserSubscriptNode.m
//  Chalk
//
//  Created by Pierre Chatelier on 14/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHParserSubscriptNode.h"

#import "CHChalkContext.h"
#import "CHChalkError.h"
#import "CHChalkErrorContext.h"
#import "CHChalkToken.h"
#import "CHChalkUtils.h"
#import "CHChalkValueEnumeration.h"
#import "CHChalkValueIndexRange.h"
#import "CHChalkValueNumberGmp.h"
#import "CHChalkValueSubscript.h"
#import "CHParserEnumerationNode.h"
#import "CHStreamWrapper.h"
#import "NSObjectExtended.h"

@implementation CHParserSubscriptNode

-(void) performEvaluationWithContext:(CHChalkContext*)context lazy:(BOOL)lazy
{
  [super performEvaluationWithContext:context lazy:lazy];
  if (!lazy || !self.evaluatedValue)
  {
    @autoreleasepool {
      CHParserEnumerationNode* enumeration = [[self->children lastObject] dynamicCastToClass:[CHParserEnumerationNode class]];
      CHChalkValueEnumeration* indicesEnumeration  = [enumeration.evaluatedValue dynamicCastToClass:[CHChalkValueEnumeration class]];
      if (indicesEnumeration)
      {
        __block NSMutableArray* indices = [[NSMutableArray alloc] initWithCapacity:indicesEnumeration.count];
        [indicesEnumeration.values enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
          CHChalkValueNumberGmp* indexValueGmp = [obj dynamicCastToClass:[CHChalkValueNumberGmp class]];
          CHChalkValueIndexRange* indexRange = [obj dynamicCastToClass:[CHChalkValueIndexRange class]];
          const chalk_gmp_value_t* indexValueGmpValue = indexValueGmp.valueConstReference;
          BOOL isValidIndex =
            indexValueGmpValue && (indexValueGmpValue->type == CHALK_VALUE_TYPE_INTEGER) &&
            mpz_fits_nsui_p(indexValueGmpValue->integer);
          if (isValidIndex)
          {
            NSNumber* number = @(mpz_get_nsui(indexValueGmpValue->integer));
            if (number)
              [indices addObject:number];
            else//if (!number)
            {
              [indices release];
              indices = nil;
              [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:indicesEnumeration.token.range] context:context];
              *stop = YES;
            }//end if (!number)
          }//end if (isValidIndex)
          else if (indexRange)
          {
            [indices addObject:indexRange];
          }//end if (indexRange)
          else//if (!isValidIndex)
          {
            [indices release];
            indices = nil;
            [self addError:[CHChalkError chalkErrorWithDomain:CHChalkErrorDomainChalk reason:CHChalkErrorOperatorArgumentsError range:indicesEnumeration.token.range] context:context];
            *stop = YES;
          }//end if (!isValidIndex)
        }];
        CHChalkValueSubscript* subscript = !indices ? nil :
          [[CHChalkValueSubscript alloc] initWithToken:indicesEnumeration.token indices:indices context:context];
        self.evaluatedValue = subscript;
        [subscript release];
        [indices release];
      }//end if (indicesEnumeration)
    }//end @autoreleasepool
    [context.errorContext.error setContextGenerator:self replace:NO];
  }//end if (!lazy || !self.evaluatedValue)
}
//end performEvaluationWithContext:

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration
{
  [self->evaluatedValue writeToStream:stream context:context presentationConfiguration:presentationConfiguration];
}
//end writeBodyToStream:context:presentationConfiguration:


@end
