//
//  CHChalkValueNumberRaw.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkValueMovable.h"
#import "CHChalkValueNumber.h"

@class CHChalkContext;
@class CHChalkValueNumberGmp;

@interface CHChalkValueNumberRaw : CHChalkValueNumber <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  chalk_raw_value_t rawValue;
  BOOL isValueWapperOnly;
}

@property(nonatomic,readonly) const chalk_raw_value_t* valueConstReference;
@property(nonatomic,readonly) chalk_raw_value_t* valueReference;

-(instancetype) initWithToken:(CHChalkToken*)token context:(CHChalkContext*)context;
-(instancetype) initWithToken:(CHChalkToken*)token value:(chalk_raw_value_t*)newRawValue naturalBase:(int)naturalBase context:(CHChalkContext*)context;

-(void) setValueReference:(chalk_raw_value_t*)newRawValue clearPrevious:(BOOL)clearPrevious isValueWapperOnly:(BOOL)aIsValueWapperOnly;

-(CHChalkValueNumberGmp*) convertToGmpValueWithContext:(CHChalkContext*)context;

-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
