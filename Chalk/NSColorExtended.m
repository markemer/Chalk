//  NSColorExtended.m
//  attributedString
//
//  Created by Pierre Chatelier on 19/05/05.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.

//This file is an extension of the NSColor class

#import "NSColorExtended.h"

@implementation NSColor (Extended)

+(NSColor*) colorWithData:(NSData*)data
{
  NSColor* result = !data ? nil : [NSKeyedUnarchiver unarchiveObjectWithData:data];
  return result;
}
//end colorWithData:

//returns the color as data
-(NSData*) colorAsData
{
  NSData* result = [NSKeyedArchiver archivedDataWithRootObject:self];
  return result;
}
//end colorAsData

+(NSColor*) colorWithRgbaString:(NSString*)string
{
  NSColor* result = nil;
  if (string)
  {
    NSScanner* scanner = [NSScanner scannerWithString:string];
    float r = 0, g = 0, b = 0, a = 0;
    BOOL ok = YES;
    ok &= [scanner scanFloat:&r];
    ok &= [scanner scanFloat:&g];
    ok &= [scanner scanFloat:&b];
    ok &= [scanner scanFloat:&a];
    result = !ok ? nil : [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a];
  }//end if (string)
  return result;
}
//end colorWithRgbaString:

-(NSString*) rgbaString
{
  NSColor* colorRGB = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace]; //the color must be RGB
  return [NSString stringWithFormat:@"%f %f %f %f", [colorRGB redComponent ], [colorRGB greenComponent],
                                                    [colorRGB blueComponent], [colorRGB alphaComponent]];
}
//end rgbaString

-(CGFloat) grayLevel
{
  return [[self colorUsingColorSpaceName:NSCalibratedWhiteColorSpace] whiteComponent];
}
//end grayLevel

-(BOOL) isRGBEqualTo:(NSColor*)other
{
  return [[self rgbaString] isEqualToString:[other rgbaString]];
}
//end isRGBEqualTo:

@end
