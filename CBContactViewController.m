//
//  CBContactViewController.m
//  Cab24
//
//  Created by Rost on 17.08.15.
//  Copyright (c) 2015 Rost. All rights reserved.
//

#import "CBContactViewController.h"
#import "CBContactCell.h"
#import "RMPhoneFormat.h"
#import "CBUserDefaultsHelper.h"
@import AddressBook;
@import AddressBookUI;


#define HEADER_VIEW_BG_COLOR    [UIColor colorWithRed:240.0f/255.0f green:239.0f/255.0f blue:245.0f/255.0f alpha:1.0f]
#define HEADER_VIEW_TEXT_COLOR  [UIColor colorWithRed:176.0f/255.0f green:174.0f/255.0f blue:175.0f/255.0f alpha:1.0f]
#define BUTTONS_COLOR           [UIColor colorWithRed:244.0f/255.0f green:191.0f/255.0f blue:0.0f/255.0f alpha:1.0f]
#define ACTIVE_TEXT_COLOR       [UIColor blackColor]

#define CHECKED_IMAGE           [UIImage imageNamed:@"CheckedImage"]
#define UNCHECKED_IMAGE         [UIImage imageNamed:@"UncheckedImage"]
#define ADD_NORMAL_IMAGE        [UIImage imageNamed:@"AddNormal"]
#define ADD_PRESSED_IMAGE       [UIImage imageNamed:@"AddPressed"]


static NSInteger const CBContactBackButtonTag = 100;
static NSInteger const CBContactSaveButtonTag = 101;

static NSInteger const CBContactMyPhoneFieldTag     = 200;
static NSInteger const CBContactOtherPhoneFieldTag  = 201;
static NSInteger const CBContactMyPhoneButtonTag    = 210;
static NSInteger const CBContactOtherPhoneButtonTag = 211;
static NSInteger const CBContactPushButtonTag       = 300;


static NSString* const CBContactPhonesCellIdentifier = @"ContactPhonesCellIdentifier";
static NSString* const CBContactPushCellIdentifier   = @"ContactPushCellIdentifier";


@interface CBContactViewController () <UITextFieldDelegate, ABPeoplePickerNavigationControllerDelegate>
@property (strong, nonatomic) NSArray *titlesArray;
@property (strong, nonatomic) NSArray *cellKeysArray;

@property (nonatomic, strong) NSMutableCharacterSet *phoneChars;
@property (nonatomic, strong) RMPhoneFormat *phoneFormat;
@property (nonatomic, assign) NSUInteger selectedTextFieldTag;
@end


@implementation CBContactViewController

- (void)loadView {
    [super loadView];
    
    self.view.backgroundColor               = [UIColor whiteColor];
    
    self.title = NSLocalizedString(@"Контакт", "");
    
    UIButton *backButton = [self createButtonWithTitle:NSLocalizedString(@"Отмена", "")
                                          andTextColor:BUTTONS_COLOR
                                              andFrame:CGRectMake(0.0f, 0.0f, 60.0f, 42.0f)
                                                andTag:CBContactBackButtonTag];
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, -10.0f, 0.0f, 0.0f)];
    
    UIButton *saveButton = [self createButtonWithTitle:NSLocalizedString(@"Сохранить", "")
                                          andTextColor:BUTTONS_COLOR
                                              andFrame:CGRectMake(0.0f, 0.0f, 75.0f, 42.0f)
                                                andTag:CBContactSaveButtonTag];
    [saveButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, -15.0f)];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:saveButton];
    
    self.cellKeysArray = @[@(CBContactTypeNotifAbout),
                           @(CBContactTypeNotifWays)];
    
    // VERY IMPORTANT DEFINITION FOR RIGHT FORMATTER WORK
    self.phoneChars = [[NSCharacterSet decimalDigitCharacterSet] mutableCopy];
    [self.phoneChars addCharactersInString:@"+*#,"];
}


- (void)buttonsSelector:(id)sender {
    UIButton *tappedButton = (UIButton *)sender;

    switch (tappedButton.tag) {
        case CBContactBackButtonTag: {
            [self backToPreviousController];
        }
            break;
        case CBContactSaveButtonTag: {
            [self.view endEditing:YES];
            [self.tableView endEditing:YES];
            
            BOOL isMyPhoneSelected = NO;
            
            // CHECK MY PHONE SELECT
            if ([[[self getButtonByTag:CBContactMyPhoneButtonTag] backgroundImageForState:UIControlStateNormal] isEqual:CHECKED_IMAGE]) {
                isMyPhoneSelected = YES;
            }
            
            NSString *phone         = [[self getTextFieldByTag:CBContactMyPhoneFieldTag].text phoneNumberString];
            NSString *otherPhone    = [[self getTextFieldByTag:CBContactOtherPhoneFieldTag].text phoneNumberString];
            
            self.model.defaultsHelper.phoneNumber       = phone;
            self.model.defaultsHelper.otherPhoneNumber  = otherPhone;
            self.order.isMyPhoneUsed = @(isMyPhoneSelected);
            
            // CHECK MY PHONE SELECT
            if ([[[self getButtonByTag:CBContactPushButtonTag] backgroundImageForState:UIControlStateNormal] isEqual:CHECKED_IMAGE])
                self.order.sendPush = @(YES);
            else if ([[[self getButtonByTag:CBContactPushButtonTag] backgroundImageForState:UIControlStateNormal] isEqual:UNCHECKED_IMAGE])
                self.order.sendPush = @(NO);
            
            NSManagedObjectContext *context = self.order.managedObjectContext;
            [context performBlockAndWait:^{
                [context save:nil];
            }];
            
            [self backToPreviousController];
        }
            break;

        case CBContactPushButtonTag: {
            if (![self isPushEnabled])
                [self showSettings];
            else {
                tappedButton = [self setCheckMarkButton:tappedButton];
            }
        }
            break;

        default:
            break;
    }
}

- (void)showAddressBook {
    ABPeoplePickerNavigationController* peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
    peoplePicker.displayedProperties = @[@(kABPersonPhoneProperty)];
    peoplePicker.peoplePickerDelegate = self;
    [self presentViewController:peoplePicker animated:YES completion:nil];
}

- (void)showSettings {
    if (&UIApplicationOpenSettingsURLString != NULL)
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    else {
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:NSLocalizedString(@"Не удалось включить опцию. \nПожалуйста убедитесь, что сервис \nвключен в Настройках системы.", nil)
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
}

- (void)setSelectedPhoneMarkerButtonByTag:(NSUInteger)tag {
    UITextField *myPhoneField = [self getTextFieldByTag:(tag - 10)];
    
    [self cleanSelectedMarkCellInTable:self.tableView withCleanSource:self.titlesArray];
    
    if ([self isValidPhoneFromText:myPhoneField.text]) {
        [[self getButtonByTag:tag] setBackgroundImage:CHECKED_IMAGE forState:UIControlStateNormal];
    } else {
        [self setAddMarkButtonFromTag:tag];
    }
}


#pragma mark - TableView dataSource & delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.titlesArray count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 25.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *sectionTitleText = self.titlesArray[section][@"section_title"];
    
    UIView *headerView = [[UIView alloc] init];
    headerView.backgroundColor = HEADER_VIEW_BG_COLOR;
    
    UIView *topLineView = [[UIView alloc] init];
    topLineView.backgroundColor = HEADER_VIEW_TEXT_COLOR;
    
    UIView *bottomLineView = [[UIView alloc] init];
    bottomLineView.backgroundColor = HEADER_VIEW_TEXT_COLOR;
    
    UILabel *sectionTitle  = [self createLabel:sectionTitleText
                                 withTextColor:HEADER_VIEW_TEXT_COLOR
                                   andFontSize:14.0f
                                      andLines:1];
    NSDictionary *subViews = @{@"topLineView"    : topLineView,
                               @"sectionTitle"   : sectionTitle,
                               @"bottomView"     : bottomLineView};
    
    NSArray *formatArray  = @[@"H:|[topLineView]|", [NSString stringWithFormat:@"V:|[topLineView(%f)]", 0.5f],
                              @"H:|-(10)-[sectionTitle]-(10)-|", @"V:|-(3)-[sectionTitle]|",
                              @"H:|[bottomView]|", [NSString stringWithFormat:@"V:[bottomView(%f)]|", 0.5f]];
    
    [self addViews:subViews toView:headerView withConstraints:formatArray];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.titlesArray[section][@"row_titles"] count];
}
#pragma mark -

#pragma mark - ABPeoplePickerNavigationController delegate
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person{
    return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
    ABMultiValueRef properties = ABRecordCopyValue(person, property);
    CFStringRef phoneRef = ABMultiValueCopyValueAtIndex(properties, identifier);
    NSString* phone = (__bridge NSString *)phoneRef;
    if (phone.length > 0) {
        [self getTextFieldByTag:self.selectedTextFieldTag].text  = [self.phoneFormat format:phone];
        [self dismissViewControllerAnimated:YES completion:nil];
        [[self getButtonByTag:(self.selectedTextFieldTag + 10)] setBackgroundImage:CHECKED_IMAGE forState:UIControlStateNormal];
    }
    
    CFRelease(phoneRef);
    CFRelease(properties);
    
    self.selectedTextFieldTag = 0;
    
    return NO;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
    [self dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark -


#pragma mark - Buttons markers and cleaner
- (UIButton *)setCheckMarkButton:(UIButton *)button {
    if ([button isSelected]) {
        [button setSelected:NO];
        [button setBackgroundImage:UNCHECKED_IMAGE forState:UIControlStateNormal];
    } else {
        [button setSelected:YES];
        [button setBackgroundImage:CHECKED_IMAGE forState:UIControlStateNormal];
    }
    
    return button;
}
#pragma mark -


#pragma mark - showErrorPhoneMessage
- (void)showErrorPhoneMessage {
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:self.title message:NSLocalizedString(@"Неверный номер телефона.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alertView show];
}
#pragma mark -


#pragma mark - Formatters and validators
- (RMPhoneFormat *)phoneFormat {
    if (_phoneFormat == nil) {
        _phoneFormat = [[RMPhoneFormat alloc] initWithDefaultCountry:@"ua"];
    }
    
    return _phoneFormat;
}

- (BOOL)isValidPhoneFromText:(NSString *)text {
    NSString *phone = [self.phoneFormat format:text];
    return [self.phoneFormat isValidAndWhitelisted:phone];
}

- (void)refreshDataAfterSettingsChanges {
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
}
#pragma mark -


#pragma mark - UI Getters
- (UITextField *)getTextFieldByTag:(NSUInteger)tag {
    return (UITextField *)[self.view viewWithTag:tag];
}

- (UIButton *)getButtonByTag:(NSUInteger)tag {
    return (UIButton *)[self.view viewWithTag:tag];
}
#pragma mark -


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
