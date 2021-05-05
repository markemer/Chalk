//
//  CHChalkValueNumberFraction.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValue.h"

@class CHChalkContext;
@class CHChalkValueNumberGmp;

@interface CHChalkValueNumberFraction : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  CHChalkValueNumberGmp* numberValue;
  NSUInteger fraction;
}

@property(nonatomic,readonly) CHChalkValueNumberGmp* numberValue;
@property(nonatomic,readonly) NSUInteger fraction;

-(instancetype) initWithToken:(CHChalkToken*)token numberValue:(CHChalkValueNumberGmp*)numberValue fraction:(NSUInteger)fraction context:(CHChalkContext*)context;

@end
