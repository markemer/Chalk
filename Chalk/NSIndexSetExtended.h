//
//  NSIndexSetExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/10/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSIndexSet (Extended)

+(instancetype) indexSetWithRange1:(NSRange)range1 range2:(NSRange)range2;
-(void) enumerateRangesWithin:(NSRange)fullRange usingBlock:(void (^)(NSRange range, BOOL inside, BOOL* stop))block;

+(instancetype) indexSet:(NSIndexSet*)indexSet positiveShift:(NSUInteger)shift;
-(NSIndexSet*) positiveShift:(NSUInteger)shift;

@end
