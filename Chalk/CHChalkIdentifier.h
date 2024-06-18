//
//  CHChalkIdentifier.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/02/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkIdentifier;

@protocol CHChalkIdentifierDependent
@required
@property                     BOOL               hasCircularDependency;
@property(readonly,retain)    CHChalkIdentifier* identifier;
@property(nonatomic,readonly) BOOL               isDynamic;
@property(readonly,retain)    NSSet*             dependingIdentifiers;

-(void) refreshIdentifierDependencies;
-(BOOL) hasIdentifierDependency:(CHChalkIdentifier*)identifier;
-(BOOL) hasIdentifierDependencyByTokens:(NSArray*)tokens;
@end

@interface CHChalkIdentifier : NSObject <NSCopying, NSSecureCoding> {
  BOOL caseSensitive;
  NSString* name;
  NSArray*  tokens;
  NSString* symbol;
  NSString* symbolAsText;
  NSString* symbolAsTeX;
}

@property(nonatomic,readonly) BOOL caseSensitive;
@property(nonatomic,copy)          NSString* name;
@property(nonatomic,readonly,copy) NSArray*  tokens;
@property(nonatomic,readonly,copy) NSString* symbol;
@property(nonatomic,readonly,copy) NSString* symbolAsText;
@property(nonatomic,readonly,copy) NSString* symbolAsTeX;

+(instancetype) ppmIdentifier;

+(instancetype) noIdentifier;
+(instancetype) unlikelyIdentifier;
+(instancetype) maybeIdentifier;
+(instancetype) certainlyIdentifier;
+(instancetype) yesIdentifier;
+(instancetype) nanIdentifier;
+(instancetype) infinityIdentifier;
+(instancetype) piIdentifier;
+(instancetype) eIdentifier;
+(instancetype) iIdentifier;
+(instancetype) jIdentifier;
+(instancetype) kIdentifier;
-(instancetype) initWithName:(NSString*)name caseSensitive:(BOOL)caseSensitive tokens:(NSArray*)tokens symbol:(NSString*)symbol symbolAsText:(NSString*)symbolAsText symbolAsTeX:(NSString*)symbolAsTeX;

-(BOOL) matchesName:(NSString*)name;
-(BOOL) matchesToken:(NSString*)token;

@end
