//
//  CHUnit.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CHUnitDescription;

@interface CHUnit : NSObject {
  NSArray* unitElements;
  NSAttributedString* richDescription_cached;
}

@property(nonatomic, readonly, copy) NSArray* unitElements;
@property(nonatomic, readonly, copy) NSAttributedString* richDescription;

-(instancetype) initWithDescription:(CHUnitDescription*)unitDescription;

@end

NS_ASSUME_NONNULL_END
