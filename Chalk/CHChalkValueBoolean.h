//
//  CHChalkValueBoolean.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValueScalar.h"

@interface CHChalkValueBoolean : CHChalkValueScalar <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  chalk_bool_t chalkBoolValue;
}

@property(nonatomic) chalk_bool_t chalkBoolValue;

+(CHChalkValueBoolean*) noValue;
+(CHChalkValueBoolean*) unlikelyValue;
+(CHChalkValueBoolean*) maybeValue;
+(CHChalkValueBoolean*) certainlyValue;
+(CHChalkValueBoolean*) yesValue;

-(instancetype) initWithToken:(CHChalkToken*)token chalkBoolValue:(chalk_bool_t)chalkBoolValue context:(CHChalkContext*)context;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;
-(void) logicalNot;

@end
