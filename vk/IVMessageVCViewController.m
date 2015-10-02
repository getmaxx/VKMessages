//
//  IVMessageVCViewController.m
//  vk
//
//  Created by Игорь Веденеев on 30.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import "IVMessageVCViewController.h"
#import "IVServerManager.h"
#import "IVUser.h"

@interface IVMessageVCViewController () <UITextFieldDelegate> {
    
    CGRect          keyboardFrame;
    UIToolbar*      test;
    UITextField*    messageField;
    UITextField*    staticMessageField;
    UIColor*        tint;
    
}

@end

@implementation IVMessageVCViewController

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    tint = self.navigationController.navigationBar.barTintColor;
    self.messageTextField.delegate = self;
    //self.messageTextField.frame.size.width = 220;
    [self.messageTextField setFrame: CGRectMake(self.messageTextField.frame.origin.x,
                                                self.messageTextField.frame.origin.y,
                                                220,
                                                30)];
    [self.messageTextField setFont: messageField.font];
    
    self.title = [NSString stringWithFormat: @"%@ %@", _friendToMessage.firstName, _friendToMessage.lastName];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(keyboardDidChanged:)
                                                 name: UIKeyboardWillChangeFrameNotification
                                               object: nil];
    
    //[self configureStaticToolbar];
    
    UIToolbar* testBar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    
    messageField = [[UITextField alloc] initWithFrame: CGRectMake(0, 0, 220, 30)];
    messageField.placeholder = @"Сообщение";
    messageField.borderStyle = UITextBorderStyleRoundedRect;
    //messageField.delegate = self;
    
    UIBarButtonItem *sendButton = [[UIBarButtonItem alloc] initWithTitle: @"Отпр."
                                                                   style: UIBarButtonItemStylePlain
                                                                  target: self
                                                                  action: @selector(sendMessageAction:)];
    [sendButton setTintColor: tint];
    
    
    UIBarButtonItem *txtfieldItem=[[UIBarButtonItem alloc]initWithCustomView: messageField];
    testBar.items = [NSArray arrayWithObjects: txtfieldItem, sendButton, nil];
    //self.toolbar.items = [NSArray arrayWithObjects: txtfieldItem, sendButton, nil];
    self.messageTextField.inputAccessoryView = testBar;
    //self.TextField.inputAccessoryView = test;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions and animations

- (IBAction)sendMessageAction:(id)sender {
    
    NSString* msg = @"";
    if (messageField.text) {
        msg = messageField.text;
    }
        
    [[IVServerManager sharedManager] sendMessage: msg
                            toFriendWithFriendID: self.friendToMessage.idOfUser];
    
    self.messageTextField.text = @"";
    messageField.text = @"";
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    //[self.messageTextField resignFirstResponder];
    //[self.testTextField resignFirstResponder];
    //[messageField resignFirstResponder];
    [messageField resignFirstResponder];
    [self becomeFirstResponder];
    
}

#pragma mark - UITextFieldDelegate

-(void) textFieldDidBeginEditing:(UITextField *)textField {
    [messageField becomeFirstResponder];
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    
    [textField resignFirstResponder];
    self.messageTextField.text = messageField.text;
}

- (void) keyboardDidChanged:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil]; //this is it!
    
    keyboardFrame = keyboardRect;
    if ([self.messageTextField isFirstResponder]) {
        //[staticMessageField resignFirstResponder];
        [messageField becomeFirstResponder];
    }

    
    
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

@end
