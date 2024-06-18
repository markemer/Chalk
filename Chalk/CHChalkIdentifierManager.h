//
//  CHChalkIdentifierManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 06/11/2014.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CHChalkIdentifier;
@class CHChalkValue;

@interface CHChalkIdentifierManager : NSObject <NSCopying> {
  NSMutableDictionary* identifiersByName;
  NSMapTable* identifierValues;
}

@property(readonly,copy) NSArray* constantsIdentifiers;
@property(readonly,copy) NSArray* variablesIdentifiers;

+(NSArray*) defaultIdentifiers;
+(NSArray*) defaultIdentifiersSymbols;
+(NSArray*) defaultIdentifiersConstants;
+(NSArray*) defaultIdentifiersFunctions;
+(BOOL)     isDefaultIdentifier:(CHChalkIdentifier*)identifier;
+(BOOL)     isDefaultIdentifierName:(NSString*)name;
+(BOOL)     isDefaultIdentifierToken:(NSString*)token;
+(instancetype) identifierManagerWithDefaults:(BOOL)withDefaults;
-(instancetype) initSharing:(CHChalkIdentifierManager*)other;
-(instancetype) init;

-(instancetype) copyWithZone:(NSZone*)zone;

-(NSString*) unusedIdentifierNameWithTokenOption:(BOOL)tokenOption;
-(NSString*) unusedIdentifierNameWithName:(NSString*)name;
-(BOOL) addIdentifier:(CHChalkIdentifier*)identifier replace:(BOOL)replace preventTokenConflict:(BOOL)preventTokenConflict;
-(BOOL) removeIdentifier:(CHChalkIdentifier*)identifier;
-(void) removeAllExceptDefaults:(BOOL)exceptDefault;
-(BOOL) hasIdentifier:(CHChalkIdentifier*)identifier;
-(BOOL) hasIdentifierName:(NSString*)name;
-(CHChalkIdentifier*) identifierForName:(NSString*)name createClass:(Class)createClass;
-(CHChalkIdentifier*) identifierForToken:(NSString*)token createClass:(Class)createClass;
-(BOOL) isDefaultIdentifier:(CHChalkIdentifier*)identifier;
-(BOOL) isDefaultIdentifierName:(NSString*)name;
-(BOOL) isDefaultIdentifierToken:(NSString*)token;
-(BOOL) isUsedIdentifierName:(NSString*)name;
-(BOOL) isUsedIdentifierToken:(NSString*)name;

-(CHChalkValue*) valueForIdentifier:(CHChalkIdentifier*)identifier;
-(CHChalkValue*) valueForIdentifierName:(NSString*)name;
-(CHChalkValue*) valueForIdentifierToken:(NSString*)token;

-(BOOL) setValue:(CHChalkValue*)value forIdentifier:(CHChalkIdentifier*)identifier;
-(BOOL) setValue:(CHChalkValue*)value forIdentifierName:(NSString*)name;
-(BOOL) setValue:(CHChalkValue*)value forIdentifierToken:(NSString*)token;

-(BOOL) removeValueForIdentifier:(CHChalkIdentifier*)identifier;
-(BOOL) removeValueForIdentifierName:(NSString*)name;
-(BOOL) removeValueForIdentifierToken:(NSString*)token;

-(NSArray<NSString*>*) constantsIdentifiersNamesMatchingPrefix:(NSString*)prefix;

@end
