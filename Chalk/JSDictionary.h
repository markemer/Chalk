//
//  JSDictionary.h
//  Chalk
//
//  Created by Pierre Chatelier on 06/02/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JSDictionary : NSObject
{
  NSDictionary* dictionary;
}

@property(retain) NSDictionary* dictionary;

+(instancetype) jsDictionary;
+(instancetype) jsDictionaryWithDictionary:(NSDictionary*)aDictionary;
-(instancetype) init;
-(instancetype) initWithDictionary:(NSDictionary*)aDictionary;
-(id) objectForKey:(id)key;

@end
