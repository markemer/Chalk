//
//  NSMutableStringExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 23/10/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NSStringExtended.h"

#if defined(USE_REGEXKITLITE) && USE_REGEXKITLITE
#else
@interface NSMutableString (RegexKitLiteExtension)
-(NSInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement;
-(NSInteger) replaceOccurrencesOfRegex:(NSString*)pattern withString:(NSString*)replacement options:(RKLRegexOptions)options range:(NSRange)searchRange error:(NSError**)error;
@end
#endif

@interface NSMutableString (Extended)
-(NSString*) string;
-(BOOL) appendCharacter:(char)character count:(NSUInteger)count;
@end
