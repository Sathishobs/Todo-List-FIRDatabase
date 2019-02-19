//
//  AppDelegate.h
//  Quiz
//
//  Created by optisol on 14/02/19.
//  Copyright © 2019 optisol. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong) NSPersistentContainer *persistentContainer;
@property (readonly, strong) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;
+ (AppDelegate *)sharedAppDelegate;
-(void)showMessage:(NSString*)message withTitle:(NSString *)title vc:(UIViewController*)viewcontroller;
-(bool)checkInternetConnection;






@end

