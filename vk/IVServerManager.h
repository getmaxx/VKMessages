//
//  IVServerManager.h
//  vk
//
//  Created by Игорь Веденеев on 29.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VKSdk/VKSdk.h>

@interface IVServerManager : NSObject <VKSdkDelegate>

@property (nonatomic, strong) NSArray* arrayOfFriends;

+ (IVServerManager*) sharedManager;

- (void) getFriendsFromServer;
- (void) sendMessage: (NSString* ) message toFriendWithFriendID: (NSNumber* ) friendID;

@end
