//
//  CHChalkErrorURLContent.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/02/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkError.h"

@interface CHChalkErrorURLContent : CHChalkError <NSCoding, NSCopying, NSSecureCoding> {
  NSURL* url;
  NSMutableIndexSet* urlContentRanges;
}

@property(nonatomic,readonly,copy) NSURL*  url;
@property(nonatomic,readonly,copy) NSIndexSet* urlContentRanges;

-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason range:(NSRange)range url:(NSURL*)url urlContentRange:(NSRange)urlContentRange;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason range:(NSRange)range url:(NSURL*)url urlContentRanges:(NSIndexSet*)urlContentRanges;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason ranges:(NSIndexSet*)ranges url:(NSURL*)url urlContentRange:(NSRange)urlContentRange;
-(instancetype) initWithDomain:(NSString*)domain reason:(NSString*)reason ranges:(NSIndexSet*)ranges url:(NSURL*)url urlContentRanges:(NSIndexSet*)urlContentRanges;

@end
