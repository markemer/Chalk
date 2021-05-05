//
//  NSMutableAttributedStringExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 23/10/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableAttributedString (Extended)
-(BOOL) appendCharacter:(char)character count:(NSUInteger)count;
@end
