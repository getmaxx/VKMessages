//
//  IVUser.h
//  vk
//
//  Created by Игорь Веденеев on 30.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

@interface IVUser : NSObject

@property(strong, nonatomic) NSString* firstName;
@property(strong, nonatomic) NSString* lastName;
@property(strong, nonatomic) NSNumber* idOfUser;
@property(strong, nonatomic) NSString* photo;
@property(strong, nonatomic) UIImage* img;
@property(strong, nonatomic) NSNumber* isOnline;

@end
