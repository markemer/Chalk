//
//  CHParseConfiguration.h
//  Chalk
//
//  Created by Pierre Chatelier on 17/01/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "CHChalkUtils.h"

@interface CHParseConfiguration : NSObject <NSCoding, NSCopying, NSSecureCoding>

@property(nonatomic) chalk_parse_mode_t parseMode;

@property(nonatomic,copy) id plist;

-(instancetype) init;
-(void) reset;

@end
