//
//  NSIndexSetExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/10/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (Extended)

+(instancetype) indexSetWithRange1:(NSRange)range1 range2:(NSRange)range2;
-(void) enumerateRangesWithin:(NSRange)fullRange usingBlock:(void (^)(NSRange range, BOOL inside, BOOL* stop))block;

@end
