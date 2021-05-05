//
//  CHGraphCurve.h
//  Chalk
//
//  Created by Pierre Chatelier on 14/12/2015.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CHChalkIdentifier.h"
#import "CHGraphUtils.h"
#import "CHParserContext.h"

@class CHChalkContext;
@class CHChalkError;
@class CHParser;
@class CHParserNode;

extern NSString* CHGraphCurveDidInvalidateNotification;

@protocol CHGraphCurveDelegate
@optional
-(void) graphCurveDidInvalidate:(NSNotification*)notification;
@end

@interface CHGraphCurve : NSObject <CHChalkIdentifierDependent, CHParserListener> {
  BOOL visible;
  NSString* input;
  NSUInteger elementPixelSize;
  CHParser* chalkParser;
  CHParserNode* chalkParserNode;
  CHChalkContext* chalkContext;
  CHChalkError* parseError;
}

@property(assign)             id delegate;
@property                     BOOL visible;
@property(copy)               NSString* name;
@property(nonatomic,copy)     NSString* input;
@property(nonatomic)          NSUInteger elementPixelSize;
@property(readonly)           chgraph_mode_t graphMode;
@property(readonly,assign)    CHParser* chalkParser;
@property(readonly,assign)    CHParserNode* chalkParserNode;
@property(readonly,assign)    CHChalkContext* chalkContext;
@property(readonly,assign)    CHChalkError* parseError;
@property                     BOOL hasCircularDependency;//CHChalkIdentifierDependent
@property(readonly,retain)    CHChalkIdentifier* identifier;//CHChalkIdentifierDependent
@property(nonatomic,readonly) BOOL isDynamic;//CHChalkIdentifierDependent
@property(readonly,retain)    NSSet* dependingIdentifiers;//CHChalkIdentifierDependent

-(instancetype) initWithContext:(CHChalkContext*)chalkContext;
-(void) performParsing;

-(void) refreshIdentifierDependencies;//CHChalkIdentifierDependent

@end
