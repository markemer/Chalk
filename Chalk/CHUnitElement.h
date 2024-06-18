//
//  CHUnitElement.h
//  Chalk
//
//  Created by Pierre Chatelier on 21/03/2021.
//  Copyright © 2005-2022 Pierre Chatelier. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <gmp.h>

NS_ASSUME_NONNULL_BEGIN

@class CHUnitElementDescription;

@interface CHUnitElement : NSObject {
  NSString* name;
  mpq_t power;
  NSString* powerAsString_cached;
}

@property(nonatomic,readonly,copy)  NSString* name;
@property(nonatomic,readonly)       mpq_srcptr power;
@property(nonatomic,readonly, copy) NSString* powerAsString;
@property(nonatomic,readonly)       BOOL isValid;

-(instancetype) initWithDescription:(CHUnitElementDescription*)description;

@end

NS_ASSUME_NONNULL_END
