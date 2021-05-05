//
//  IJSVGUnitLength.m
//  IJSVGExample
//
//  Created by Curtis Hard on 13/01/2017.
//  Copyright © 2017 Curtis Hard. All rights reserved.
//

#import "IJSVGUnitLength.h"

@implementation IJSVGUnitLength

@synthesize value;
@synthesize type;
@synthesize inherit;

+ (IJSVGUnitLength *)unitWithFloat:(CGFloat)number
{
    IJSVGUnitLength * unit = [[[self alloc] init] autorelease];
    unit.value = number;
    unit.type = IJSVGUnitLengthTypeNumber;
    return unit;
}

+ (IJSVGUnitLength *)unitWithFloat:(CGFloat)number
                              type:(IJSVGUnitLengthType)type
{
    IJSVGUnitLength * unit = [[[self alloc] init] autorelease];
    unit.value = number;
    unit.type = type;
    return unit;
}

+ (IJSVGUnitLength *)unitWithPercentageFloat:(CGFloat)number
{
    return [self unitWithFloat:number
                          type:IJSVGUnitLengthTypePercentage];
}

+ (IJSVGUnitLength *)unitWithPercentageString:(NSString *)string
{
    IJSVGUnitLength * unit = [self unitWithString:string];
    unit.type = IJSVGUnitLengthTypePercentage;
    return unit;
}

+ (IJSVGUnitLength *)unitWithString:(NSString *)string
{
    IJSVGUnitLength * unit = [[[self alloc] init] autorelease];
    unit.value = [string floatValue];
    unit.type = IJSVGUnitLengthTypeNumber;
    if([string hasSuffix:@"%"] == YES) {
        unit.type = IJSVGUnitLengthTypePercentage;
    }
    return unit;
}

- (CGFloat)computeValue:(CGFloat)anotherValue
{
    if(self.type == IJSVGUnitLengthTypePercentage) {
        return ((anotherValue/100)*self.value);
    }
    return self.value;
}

- (CGFloat)valueAsPercentage
{
    return self.value/100;
}

- (NSString *)stringValue
{
    if(self.type == IJSVGUnitLengthTypePercentage) {
        return [NSString stringWithFormat:@"%g%%",self.value];
    }
    return [NSString stringWithFormat:@"%g",self.value];
}

@end
