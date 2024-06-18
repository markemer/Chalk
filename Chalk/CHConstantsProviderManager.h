//
//  CHConstantsProviderManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 03/04/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHConstantsProvider;

@interface CHConstantsProviderManager : NSObject {
  NSMutableArray<CHConstantsProvider*>* constantsProviders;
}

+(CHConstantsProviderManager*) sharedConstantsProviderManager;

@property(nonatomic,readonly,copy) NSArray<CHConstantsProvider*>* constantsProviders;

-(void) addConstantsProvider:(CHConstantsProvider*)constantsProvider;

@end

NS_ASSUME_NONNULL_END
