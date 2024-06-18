//
//  CHUnit.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHUnitElementDescription;

@interface CHUnitDescription : NSObject {
  NSString* uid;
  NSArray<CHUnitElementDescription*>* unitElementsDescriptions;
}

@property(nonatomic, readonly, copy) NSString* uid;
@property(nonatomic, readonly, copy) NSArray<CHUnitElementDescription*>* unitElementsDescriptions;

-(instancetype) initWithPlist:(id)plist;

@end

NS_ASSUME_NONNULL_END
