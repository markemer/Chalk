//
//  NSDataExtended.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/12/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <stdio.h>

@interface NSData (Extended)

-(FILE*) openAsFile;
-(NSData*) bzip2Decompressed;

@end
