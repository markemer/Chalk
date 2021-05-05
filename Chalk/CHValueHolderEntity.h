//
//  CHValueHolderEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 12/01/2020.
//  Copyright © 2020 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

NS_ASSUME_NONNULL_BEGIN

@interface CHValueHolderEntity : NSManagedObject

+(NSString*) entityName;

@end

NS_ASSUME_NONNULL_END
