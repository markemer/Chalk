//
//  CHChalkErrorContext.h
//  Chalk
//
//  Created by Pierre Chatelier on 18/03/2014.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkError;

@interface CHChalkErrorContext : NSObject {
  NSString* input;
  CHChalkError* error;
  NSMutableArray* warnings;
}

-(instancetype) initWithString:(NSString*)string;

@property(nonatomic,readonly) BOOL hasError;
@property(nonatomic,readonly,copy) NSString* input;
@property(nonatomic,readonly,retain) CHChalkError* error;
@property(nonatomic,readonly,copy) NSArray* warnings;

-(void) reset:(NSString*)value;
-(BOOL) setError:(CHChalkError*)value replace:(BOOL)replace;
-(void) addWarning:(CHChalkError*)value;

@end
