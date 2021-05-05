//
//  CHChalkValueToStringTransformer.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkContext;
@class CHChalkValueParser;
@interface CHChalkValueToStringTransformer : NSValueTransformer {
  CHChalkContext* chalkContext;
  CHChalkValueParser* valueParser;
}

+(NSString*) name;

+(id) transformerWithContext:(CHChalkContext*)context;
-(id) initWithContext:(CHChalkContext*)context;

@end
