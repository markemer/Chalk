//
//  CHBoolTransformer.h
// Chalk
//
//  Created by Pierre Chatelier on 27/04/09.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CHBoolTransformer : NSValueTransformer {
  id falseValue;
  id trueValue;
}
//end CHBoolTransformer

+(NSString*) name;

+(id) transformerWithFalseValue:(id)falseValue trueValue:(id)trueValue;
-(id) initWithFalseValue:(id)falseValue trueValue:(id)trueValue;

@end
