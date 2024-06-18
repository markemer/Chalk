//
//  NSAttributedStringExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 18/03/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSAttributedString (Extended)

+(instancetype) attributedString;
+(instancetype) attributedStringWithString:(NSString*)string;

-(NSRange) range;

@end
