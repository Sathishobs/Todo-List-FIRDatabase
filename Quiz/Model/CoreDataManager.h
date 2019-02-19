//
//  CoreDataManager.h
//  Quiz
//
//  Created by optisol on 14/02/19.
//  Copyright © 2019 optisol. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol DataManagerDelegate;

@interface CoreDataManager : NSObject
{
    NSManagedObjectContext * managedObjectContext;
    NSManagedObjectModel * managedObjectModel;
    NSPersistentStoreCoordinator * persistentStoreCoordinator;
}
// get a singleton object of this class
+ (CoreDataManager *)sharedInstance;

// get a global context
+ (NSManagedObjectContext *)globalContext;

// save a context
+ (NSError *)saveContext:(NSManagedObjectContext *)context;

// insert a record to an existing table
+ (NSError *)insertARecordWithRecordValues:(NSDictionary *)values ToTable:(NSString *)tableName InContext:(NSManagedObjectContext *)context;

// delete a record from an existing table
+ (NSError *)deleteARecord:(NSManagedObject *)record InContext:(NSManagedObjectContext *)context;

// update a record for a property (if the record exists) in an existing table
+ (NSError *)updateARecord:(NSManagedObject *)record WithNewRecordValues:(NSDictionary *)values InTable:(NSString *)tableName InContext:(NSManagedObjectContext *)context;

// fetch all records from a single table
+ (NSMutableArray *)fetchAllRecordsFromTable:(NSString *)tableName InContext:(NSManagedObjectContext *)context;

// fetch records matched by a predicate
+ (NSMutableArray *)fetchRecordsFromTable:(NSString *)tableName MatchedByPredicate:(NSPredicate *)predicate InContext:(NSManagedObjectContext *)context;

// fetch records defined by the criteria in NSFetchRequest
+ (NSMutableArray *)fetchRecordsWithFetchRequest:(NSFetchRequest *)request InContext:(NSManagedObjectContext *)context;

+ (bool)checkDuplicateRecord:(NSString *)userStr;
+ (void)deleteAllEntities:(NSManagedObjectContext*)context;

@end

