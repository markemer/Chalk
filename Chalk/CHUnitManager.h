//
//  CHUnitManager.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHUnit;
@class CHUnitDescription;

@interface CHUnitManager : NSObject {
  NSMutableDictionary<NSString*, CHUnit*>* units;
}

+(CHUnitManager*) sharedUnitManager;
-(instancetype) init;

-(CHUnit*) unitWithPlist:(id)plist;

@end

NS_ASSUME_NONNULL_END
