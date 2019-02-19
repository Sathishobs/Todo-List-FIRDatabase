//
//  AddEditTaskViewController.m
//  Quiz
//
//  Created by optisol on 14/02/19.
//  Copyright © 2019 optisol. All rights reserved.
//

#import "AddEditTaskViewController.h"
#import "Appdelegate.h"
#import "ConstantString.h"
#import <CoreData/CoreData.h>
#import "CoreDataManager.h"
#import <FirebaseDatabase/FirebaseDatabase.h>
#import <FirebaseCore/FirebaseCore.h>

@interface AddEditTaskViewController () {
    // Variable Declaration
    NSManagedObjectContext* context;
}

// IBOutlets
@property (weak, nonatomic) IBOutlet UINavigationBar *navBar;
@property (weak, nonatomic) IBOutlet UITextField *taskTextField;

// Firebase Variable Declaration
@property (strong, nonatomic) FIRDatabaseReference *fireDBRef;

@end

@implementation AddEditTaskViewController

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Core data and fire base reference
    context = [AppDelegate sharedAppDelegate].managedObjectContext;
    self.fireDBRef = [[FIRDatabase database] reference];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Prefill data for edit task handler
    if (self.isEditTask == YES) {
        self.taskTextField.text = self.taskName;
        self.navBar.topItem.title = QEdit;
    }
    [self.taskTextField becomeFirstResponder];
}

#pragma mark - Button IBActions
- (IBAction)saveButtonClikced:(id)sender {
    
    if ([CoreDataManager checkDuplicateRecord:_taskTextField.text]) {
        // Handling duplicate record
        [[AppDelegate sharedAppDelegate] showMessage:QDupilated withTitle:QAlert vc:self];
    } else {
        
        [self.taskTextField resignFirstResponder];
        NSMutableDictionary *insertDict =[[NSMutableDictionary alloc]init];
        
        // New task or edit task identification flag
        if (self.isEditTask == YES) {
            
            // Edit and update older task
            [insertDict setObject:_taskTextField.text forKey:QTaskAttr];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"task LIKE[c] %@", self.taskName];
            [[self.fireDBRef child: self.taskName] removeValue];
            [[self.fireDBRef child: _taskTextField.text] setValue: _taskTextField.text]; //updating in firebase
            NSMutableArray *arry = [CoreDataManager fetchRecordsFromTable:QEntityname MatchedByPredicate:predicate InContext:context];
            NSManagedObject* managedobj = (NSManagedObject *)arry;
            NSError *error = [CoreDataManager updateARecord:managedobj WithNewRecordValues:insertDict InTable:QEntityname InContext:context];
            
            // Handling error case
            if (error != nil) {
                [[AppDelegate sharedAppDelegate] showMessage:QUpdateFailure withTitle:QAlert vc:self];
            }
            
        } else {
            // Triming whitespaces
            _taskTextField.text = [_taskTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            // Validate task name with special characters which FIR DB restricted in Validate Form
            NSString *specialCharacterString = @"!~`@#$%^&*-+();:={}[],.<>?\\/\"\'";
            NSCharacterSet *specialCharacterSet = [NSCharacterSet
                                                   characterSetWithCharactersInString:specialCharacterString];
            
            if ([ _taskTextField.text.lowercaseString rangeOfCharacterFromSet:specialCharacterSet].length) {
                NSLog(@"contains special characters");
                [[AppDelegate sharedAppDelegate] showMessage:QRegexValidate withTitle:QAlert vc:self];
                return;
            }
            
            if (_taskTextField.text.length > 0) {
            // save new task to coredata
            [insertDict setObject:_taskTextField.text forKey:QTaskAttr];
            NSError *error = [CoreDataManager insertARecordWithRecordValues:insertDict ToTable:QEntityname InContext:context];
            [[self.fireDBRef child:_taskTextField.text] setValue:_taskTextField.text]; //saving in firebase
            
            // Handling error case
            if (error != nil) {
                [[AppDelegate sharedAppDelegate] showMessage:QUpdateFailure withTitle:QAlert vc:self];
            }
                
            }else{
                [[AppDelegate sharedAppDelegate] showMessage:QNoValidText withTitle:QAlert vc:self];
            }
        }
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// Cancel button action
- (IBAction)cancelButtonClicked:(id)sender {
    [self.taskTextField resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)validateCharacters:(NSString *)string{
 
    NSString *specialCharacterString = @"!~`@#$%^&*-+();:={}[],.<>?\\/\"\'";
    NSCharacterSet *specialCharacterSet = [NSCharacterSet
                                           characterSetWithCharactersInString:specialCharacterString];
    
    if ([string.lowercaseString rangeOfCharacterFromSet:specialCharacterSet].length) {
        NSLog(@"contains special characters");
        return NO;
    }
    return YES;
}

@end
