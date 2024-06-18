//
//  NSCoder.h
//  Chalk
//
//  Created by Pierre Chatelier on 09/02/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCoder (Extended)

-(NSRange) decodeRangeForKey:(NSString*)key;
-(NSUInteger) decodeUnsignedIntegerForKey:(NSString*)key;

-(void) encodeRange:(NSRange)range forKey:(NSString*)key;
-(void) encodeUnsignedInteger:(NSUInteger)value forKey:(NSString*)key;

@end
