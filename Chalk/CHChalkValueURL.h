//
//  CHChalkValueURL.h
//  Chalk
//
//  Created by Pierre Chatelier on 01/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import "CHChalkValue.h"

@interface CHChalkValueURL : CHChalkValue <NSCoding, NSCopying, NSSecureCoding, CHChalkValueMovable> {
  NSURL* url;
}

@property(copy) NSURL* url;

-(instancetype) initWithToken:(CHChalkToken*)token url:(NSURL*)url context:(CHChalkContext*)context;
-(void) writeBodyToStream:(CHStreamWrapper*)stream context:(CHChalkContext*)context presentationConfiguration:(CHPresentationConfiguration*)presentationConfiguration;

@end
