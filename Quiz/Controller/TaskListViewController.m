//
//  TaskListViewController.m
//  Quiz
//
//  Created by optisol on 14/02/19.
//  Copyright © 2019 optisol. All rights reserved.
//
#import "TaskListViewController.h"
#import "AddEditTaskViewController.h"
#import "Appdelegate.h"
#import "TaskTableViewCell.h"
#import "ConstantString.h"
#import <CoreData/CoreData.h>
#import "CoreDataManager.h"
#import <FirebaseDatabase/FirebaseDatabase.h>
#import <FirebaseCore/FirebaseCore.h>

@interface TaskListViewController ()<UITableViewDelegate, UITableViewDataSource> {
    // Variable Declaration
    NSMutableArray *taskArray;
    NSManagedObjectContext* context;
    
}
// IBOutlets
@property (weak, nonatomic) IBOutlet UILabel *noTaskFoundLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

// Firebase Variable Declaration
@property (strong, nonatomic) FIRDatabaseReference *fireDBRef;

@end

@implementation TaskListViewController

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initializing setup of table view controller
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
    // initializing firebase DB and settings
    self.fireDBRef = [[FIRDatabase database] reference];
    context = [AppDelegate sharedAppDelegate].managedObjectContext;
    [self firebaseAutoUpdate];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([AppDelegate sharedAppDelegate].checkInternetConnection == NO) {
        // Offline fetch data from local database
        NSMutableArray *tempArray = [[CoreDataManager fetchAllRecordsFromTable:QEntityname InContext:context]mutableCopy];
        self->taskArray = [[[tempArray reverseObjectEnumerator] allObjects] mutableCopy];
        [self showTableview];
    }
}

#pragma mark - Business Logic
-(void)firebaseAutoUpdate {
    context = [AppDelegate sharedAppDelegate].managedObjectContext;
    taskArray = [[NSMutableArray alloc]init];
    __block NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    
    if ([AppDelegate sharedAppDelegate].checkInternetConnection == YES) {
        // Syn firebase and coredata
        [CoreDataManager deleteAllEntities:context];
        [self.fireDBRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            // Auto Called when firebase data base changed
            if ([AppDelegate sharedAppDelegate].checkInternetConnection != NO) {
                [self->taskArray removeAllObjects];
                NSDictionary *firebasDB = snapshot.value;
                if (firebasDB != (id)[NSNull null]) {
                    NSArray *fireDBValues = firebasDB.allValues;
                    NSManagedObjectContext *newContext = [AppDelegate sharedAppDelegate].managedObjectContext;
                    NSError *error;
                    
                    // Adding a data into Dictionary
                    [CoreDataManager deleteAllEntities:self->context];
                    for(int i = 0; i<fireDBValues.count; i++) {
                        NSMutableDictionary *insertDict =[[NSMutableDictionary alloc]init];
                        [insertDict setObject:fireDBValues[i] forKey:QTaskAttr];
                        error = [CoreDataManager insertARecordWithRecordValues:insertDict ToTable:QEntityname InContext:newContext];
                    }
                    
                    // Initializing array to collect values from local storage and assign it to task array
                     self->taskArray = [[NSMutableArray alloc] init];
                     self->taskArray = [[CoreDataManager fetchAllRecordsFromTable:QEntityname InContext:newContext]mutableCopy];
                }
                [self showTableview];
            }
        }];
    } else {
        // No internet connection get values from core data
        tempArray = [[CoreDataManager fetchAllRecordsFromTable:QEntityname InContext:context]mutableCopy];
        taskArray = [[[tempArray reverseObjectEnumerator] allObjects] mutableCopy];
        [self showTableview];
    }
}

-(void)showTableview {
    if (taskArray.count != 0) {
        // data found in local or firebase
        [self.noTaskFoundLabel setHidden:YES];
        [self.tableView setHidden:NO];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self.tableView reloadData];
    } else {
        // No record found
        [self.noTaskFoundLabel setHidden:NO];
        [self.tableView setHidden:YES];
    }
    [self.tableView reloadData];
}

#pragma mark - Button IBActions
- (IBAction)addButtonClikced:(id)sender {
    // Add new task
    AddEditTaskViewController *add = [self.storyboard instantiateViewControllerWithIdentifier: QTaskListVC];
    [self presentViewController:add animated:YES completion:nil];
}

#pragma mark - UITableviewDataSouce
- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return taskArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *simpleTableIdentifier = QTaskListCell;
    TaskTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    if (cell == nil) {
        cell = [[TaskTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    cell.taskLabel.text = [[taskArray valueForKey:QTaskAttr] objectAtIndex:indexPath.row];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigate to edit mode on user tap of data
    AddEditTaskViewController *add = [self.storyboard instantiateViewControllerWithIdentifier:QTaskListVC];
    add.isEditTask = YES;
    add.taskName = [[taskArray valueForKey:QTaskAttr] objectAtIndex:indexPath.row];
    [self presentViewController:add animated:YES completion:nil];
}

// UITableViewCell swipe to delete option enable
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

// Handle swipe to delete action
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(editingStyle==UITableViewCellEditingStyleDelete)
    {
        // Removing values from firebase database
        NSString *deleteKey = [[taskArray valueForKey:QTaskAttr] objectAtIndex:indexPath.row];
        [[self.fireDBRef child:deleteKey] removeValue];
        NSManagedObject *mngobj = [taskArray objectAtIndex:indexPath.row];
        NSError *error = [CoreDataManager deleteARecord:mngobj InContext:context];
        NSLog(@"error = %@",error);
        
        //Removing values from local
        [taskArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSMutableArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView setEditing:NO animated:YES];
        [[AppDelegate sharedAppDelegate] showMessage:QDeleteTask withTitle:QAlert vc:self];
        
        if (taskArray.count != 0) {
            [self.noTaskFoundLabel setHidden:YES];
            [self.tableView setHidden:NO];
            [self.tableView reloadData];
        } else {
            [self.noTaskFoundLabel setHidden:NO];
            [self.tableView setHidden:YES];
        }
    }
}

@end
