//
//  CHConstantsProvider.h
//  Chalk
//
//  Created by Pierre Chatelier on 15/07/13.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "CHChalkTypes.h"

@interface CHConstantsProvider : NSObject {
  NSMutableArray* constantDescriptions;
}

@property(nonatomic,copy) NSString* name;
@property(nonatomic,readonly) NSString* nameNotEmpty;
@property(nonatomic,copy) NSString* author;
@property(nonatomic,copy) NSString* version;
@property(nonatomic,copy) NSString* comments;
@property(nonatomic,readonly,copy) NSArray* constantDescriptions;

-(instancetype) initWithURL:(NSURL*)url;
-(instancetype) initWithPlist:(id)plist;

@end
