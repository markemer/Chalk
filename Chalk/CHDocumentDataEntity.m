//
//  CHDocumentDataEntity.m
//  Chalk
//
//  Created by Pierre Chatelier on 19/11/2016.
//  Copyright (c) 2017-2022 Pierre Chatelier. All rights reserved.
//

#import "CHDocumentDataEntity.h"

#import "NSObjectExtended.h"

@interface CHDocumentDataEntity()
+(CHDocumentDataEntity*) getInstanceInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;
@end

@implementation CHDocumentDataEntity

+(NSString*) entityName {return @"CHDocumentData";}

+(CHDocumentDataEntity*) getInstanceInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
  __block CHDocumentDataEntity* result = nil;
  NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:[self entityName]];
  NSError* error = nil;
  NSArray* objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
  [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    result = [obj dynamicCastToClass:[CHDocumentDataEntity class]];
    if (result)
      *stop = YES;
  }];
  [fetchRequest release];
  return result;
}
//end getInstanceInManagedObjectContext:

+(NSData*) getDataInManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
  NSData* result = nil;
  CHDocumentDataEntity* instance = [self getInstanceInManagedObjectContext:managedObjectContext];
  result = [instance valueForKey:@"data"];//instance.data;
  return result;
}
//end getDataInManagedObjectContext:

+(void) setData:(NSData*)data inManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
  CHDocumentDataEntity* instance = [self getInstanceInManagedObjectContext:managedObjectContext];
  if (!instance)
  {
    NSEntityDescription* entityDescription =
      [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:managedObjectContext];
    instance = [[[CHDocumentDataEntity alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:managedObjectContext] autorelease];
  }//end if (!instance)
  [instance setValue:data forKey:@"data"];
}
//end setData:inManagedObjectContext:

@end
