//  NSColorExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/05/05.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.

//This file is an extension of the NSColor class

#import <Cocoa/Cocoa.h>

@interface NSColor (Extended)

+(NSColor*) colorWithData:(NSData*)data;
-(NSData*) colorAsData;
+(NSColor*) colorWithRgbaString:(NSString*)string;
-(NSString*) rgbaString;
-(CGFloat) grayLevel;
-(BOOL) isRGBEqualTo:(NSColor*)other;

@end
