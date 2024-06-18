//
//  NSUserDefaultsExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/10/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (Extended)

-(NSUInteger) unsignedIntegerForKey:(NSString*)key;
-(void) setUnsignedInteger:(NSUInteger)value forKey:(NSString*)key;

@end
