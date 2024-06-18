//
//  CHChalkToken.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CHChalkToken : NSObject <NSCoding, NSCopying, NSSecureCoding> {
  NSString* value;
  NSRange   range;
}

@property(nonatomic,copy) NSString* value;
@property(nonatomic)      NSRange   range;

+(instancetype) chalkTokenEmpty;
+(instancetype) chalkTokenUnion:(NSArray*)tokens;
+(instancetype) chalkTokenWithValue:(NSString*)value range:(NSRange)range;

-(instancetype) init;
-(instancetype) initWithValue:(NSString*)value range:(NSRange)range;

-(void) unionWithTokens:(NSArray*)tokens;
-(void) unionWithToken:(CHChalkToken*)token;

@end
