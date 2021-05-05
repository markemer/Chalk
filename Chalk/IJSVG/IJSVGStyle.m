//
//  IJSVGStyle.m
//  IJSVGExample
//
//  Created by Curtis Hard on 03/09/2014.
//  Copyright (c) 2014 Curtis Hard. All rights reserved.
//

#import "IJSVGStyle.h"
#import "IJSVGUtils.h"

@implementation IJSVGStyle

- (void)dealloc
{
    [_dict release], _dict = nil;
    [super dealloc];
}

- (id)init
{
    if( ( self = [super init] ) != nil ) {
        _dict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)setPropertyValue:(id)value
             forProperty:(NSString *)key
{
    [_dict setObject:value
              forKey:key];
}

- (NSDictionary *)properties
{
    return _dict;
}

- (id)property:(NSString *)key
{
    return [_dict objectForKey:key];
}

+ (IJSVGStyle *)parseStyleString:(NSString *)string
{
    static NSRegularExpression * _reg = nil;
    static dispatch_once_t onceToken;
    IJSVGStyle * style = [[[self class] alloc] init];
    dispatch_once(&onceToken, ^{
        _reg = [[NSRegularExpression alloc] initWithPattern:@"([a-zA-Z\\-]+)\\:([^;]+)\\;?"
                                                    options:0
                                                      error:nil];
    });
    [_reg enumerateMatchesInString:string
                           options:0
                             range:NSMakeRange( 0, string.length )
                        usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
         NSString * key = [string substringWithRange:[result rangeAtIndex:1]];
         NSString * value = [string substringWithRange:[result rangeAtIndex:2]];
         [[self class] computeStyleProperty:key
                                      value:value
                                      style:style];
     }];
    return [style autorelease];
}

+ (NSString *)trimString:(NSString *)string
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

+ (NSArray *)allowedColourKeys
{
    return @[@"fill",@"stroke-colour",@"stop-color",@"stroke"];
}

+ (void)computeStyleProperty:(NSString *)key
                       value:(NSString *)value
                       style:(IJSVGStyle *)style
{
    key = [[self class] trimString:key];
    value = [[self class] trimString:value];
    [style setPropertyValue:value
                forProperty:key];
    
}

+ (BOOL)isNumeric:(NSString *)string
{
    return [[NSScanner scannerWithString:string] scanFloat:NULL];
}

- (void)setProperties:(NSDictionary *)properties
           replaceAll:(BOOL)flag
{
    if(flag) {
        [_dict removeAllObjects];
    }
    [_dict addEntriesFromDictionary:properties];
}

- (NSString *)description
{
    return [_dict description];
}

- (IJSVGStyle *)mergedStyle:(IJSVGStyle *)style
{
    // create the new style
    IJSVGStyle * newStyle = [[[IJSVGStyle alloc] init] autorelease];
    
    // grab the current style
    NSMutableDictionary * dict = [[[self properties] mutableCopy] autorelease];
    
    // overwride the style with the new styles
    [dict addEntriesFromDictionary:[style properties]];
    
    // add the styles to the style
    [newStyle setProperties:dict
                 replaceAll:YES];
    return newStyle;
}

@end
