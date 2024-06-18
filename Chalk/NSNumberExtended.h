//
//  NSNumberExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 05/12/2015.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (Extended)

+(NSNumber*) numberWithString:(NSString*)string;
-(instancetype) initWithString:(NSString*)string;

-(BOOL) fitsInteger;
-(BOOL) fitsUnsignedInteger;

-(NSNumber*) numberByAdding:(NSNumber*)other;
-(NSNumber*) numberBySubtracting:(NSNumber*)other;

@end
