//
//  CBContactCell.m
//  Cab24
//
//  Created by Rost on 18.08.15.
//  Copyright (c) 2015 Rost. All rights reserved.
//

#import "CBContactCell.h"


#define  SUBTITLE_TEXT_COLOR    [UIColor colorWithRed:192.0f/255.0f green:191.0f/255.0f blue:197.0f/255.0f alpha:1.0f]

@interface CBContactCell ()
@property (strong, nonatomic) NSDictionary *viewsDictionary;
@property (strong, nonatomic) NSArray *formatsArray;
@property (assign, nonatomic) BOOL verticalCenterFlag;
@end


@implementation CBContactCell

#pragma mark - Constructor
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withKey:(NSUInteger)key {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        UIView *separatorLineView = [[UIView alloc] init];
        separatorLineView.backgroundColor = [UIColor lightGrayColor];
        
        void (^createNotifAboutCell)() = ^() {
            self.cellRadioButton  = [self createButtonWithImage:@"UncheckedImage"];
            
            self.cellTitleLabel    = [self createLabelWithTextColor:[UIColor blackColor] andFontSize:CBFontRegularSize];
            self.cellUnderLineView = [[UIView alloc] init];
            self.cellUnderLineView.backgroundColor = [UIColor colorWithRed:244.0f/255.0f green:191.0f/255.0f blue:0.0f/255.0f alpha:1.0f];
            self.cellValueTextField = [self createTextField];
            
            self.viewsDictionary = @{@"radioButton"    : self.cellRadioButton,
                                     @"titleLabel"     : self.cellTitleLabel,
                                     @"underLineView"  : self.cellUnderLineView,
                                     @"valueTextField" : self.cellValueTextField};
            
            self.formatsArray = @[@"H:|-(10)-[titleLabel(80)]-(5)-[valueTextField]-(5)-[radioButton(22)]-(10)-|",
                                  @"H:|-(95)-[underLineView]-(45)-|",
                                  @"V:[titleLabel(20)]",
                                  @"V:[radioButton(22)]",
                                  @"V:[underLineView(2)]-(5)-|",
                                  @"V:[valueTextField(40)]-(1)-|"];
        };
        
        createNotifAboutCell();
        
        [self addViews:self.viewsDictionary toView:self.contentView withConstraints:self.formatsArray];
    }
    
    return self;
}
#pragma mark -


#pragma mark - createTextField
- (UITextField *)createTextField {
    UITextField *newTextField       = [[UITextField alloc] initWithFrame:CGRectZero];

    newTextField.textColor          = [UIColor blackColor];
    newTextField.backgroundColor    = [UIColor clearColor];
    newTextField.returnKeyType      = UIReturnKeyDefault;
    newTextField.placeholder        = @"";
    newTextField.textAlignment      = NSTextAlignmentLeft;
    newTextField.clearButtonMode    = UITextFieldViewModeAlways;
    newTextField.borderStyle        = UITextBorderStyleNone;
    newTextField.keyboardType       = UIKeyboardTypePhonePad;
    [newTextField setFont:[UIFont applicationFontOfSize:CBFontRegularSize]];
    
    return newTextField;
}
#pragma mark -

@end
