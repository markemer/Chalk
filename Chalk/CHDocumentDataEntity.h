//
//  CHDocumentDataEntity.h
//  Chalk
//
//  Created by Pierre Chatelier on 19/11/2016.
//  Copyright (c) 2005-2020 Pierre Chatelier. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface CHDocumentDataEntity : NSManagedObject

+(NSString*) entityName;

+(NSData*) getDataInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+(void) setData:(NSData*)data inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
