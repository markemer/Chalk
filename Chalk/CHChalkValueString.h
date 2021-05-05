//
//  CHChalkValueString.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValue.h"

@interface CHChalkValueString : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  NSString* stringValue;
}

@property(copy) NSString* stringValue;

-(instancetype) initWithToken:(CHChalkToken*)token string:(NSString*)string context:(CHChalkContext*)context;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
