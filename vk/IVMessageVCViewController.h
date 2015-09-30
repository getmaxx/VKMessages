//
//  IVMessageVCViewController.h
//  vk
//
//  Created by Игорь Веденеев on 30.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import <UIKit/UIKit.h>

@class IVUser;

@interface IVMessageVCViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendMessage;
@property (strong, nonatomic) IVUser* friendToMessage;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UITextField *testTextField;

- (IBAction)sendMessageAction:(id)sender;

@end
