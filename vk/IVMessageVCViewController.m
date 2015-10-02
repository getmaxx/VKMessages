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
    UITextField*    toolbarTextField;
    UIColor*        tint;
    UIBarButtonItem *sendButton;
    
    BOOL isEditing;
    
}

@end

@implementation IVMessageVCViewController

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void) viewDidDisappear:(BOOL)animated {
    
    self.toolbar.tintColor = [UIColor grayColor];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    isEditing = NO;
    [toolbarTextField addTarget: self
                         action: @selector(textFieldDidChange:)
               forControlEvents: UIControlEventEditingChanged];
    
    self.navigationController.toolbarHidden = YES;
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
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(textFieldDidChange:)
                                                 name: UITextFieldTextDidChangeNotification
                                               object: nil];

    [self setUpToolbar];
    
}

- (void) setUpToolbar {
    
    UIToolbar* testBar = [[UIToolbar alloc] initWithFrame: CGRectMake(0,
                                                                      self.view.bounds.size.height - 44,
                                                                      self.view.bounds.size.width,
                                                                      44)];
    testBar.tintColor = tint;
    
    toolbarTextField = [[UITextField alloc] initWithFrame: CGRectMake(0, 0, 220, 30)];
    toolbarTextField.placeholder = @"Сообщение";
    toolbarTextField.borderStyle = UITextBorderStyleRoundedRect;
    toolbarTextField.delegate = self;
    toolbarTextField.tintColor = tint;
    UIBarButtonItem *txtfieldItem=[[UIBarButtonItem alloc]initWithCustomView: toolbarTextField];
    
    sendButton = [[UIBarButtonItem alloc] initWithTitle: @"Отпр."
                                                  style: UIBarButtonItemStylePlain
                                                 target: self
                                                 action: @selector(sendMessageAction:)];
    sendButton.enabled = NO;
    [sendButton setTintColor: tint];
    
    self.navigationController.toolbar.tintColor = tint;
    
    NSArray* barArray = [NSArray arrayWithObjects: txtfieldItem, sendButton, nil];
    
    testBar.items = barArray;
    [self.view addSubview: testBar];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions and animations

- (IBAction)sendMessageAction:(id)sender {
    
    NSString* msg = toolbarTextField.text;
    
    [[IVServerManager sharedManager] sendMessage: msg
                            toFriendWithFriendID: self.friendToMessage.idOfUser];
    
    toolbarTextField.text = @"";
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    
    //if ([toolbarTextField isFirstResponder]) {
        [toolbarTextField resignFirstResponder];
            NSLog(@"y^ %f", self.view.frame.origin.y + keyboardFrame.size.height);
    //}
    
    //[self becomeFirstResponder];
    
}

#pragma mark - UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField {
    //sendButton.enabled = YES;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    if ([textField.text isEqualToString: @""]) {
        sendButton.enabled = NO;
    }
}

- (void) textFieldDidChange: (UITextField *) theTextField{
    
    if (![toolbarTextField.text isEqualToString: @""]) {
        sendButton.enabled = YES;
    } else {
        sendButton.enabled = NO;

    }

}

- (void) keyboardDidChanged:(NSNotification *)notification {
    CGRect keyboardRect = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil]; //this is it!
    
    keyboardFrame = keyboardRect;
    isEditing = !isEditing;
    
    if (isEditing) {
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y - keyboardFrame.size.height - self.toolbar.frame.size.height,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);

    }
    else {
        self.view.frame = CGRectMake(self.view.frame.origin.x,
                                     self.view.frame.origin.y + keyboardFrame.size.height,// + self.toolbar.frame.size.height,
                                     self.view.frame.size.width,
                                     self.view.frame.size.height);

    }
    NSLog(@"y k %f", self.view.frame.origin.y + keyboardFrame.size.height);
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

@end
