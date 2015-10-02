//
//  IVServerManager.m
//  vk
//
//  Created by Игорь Веденеев on 29.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import "IVServerManager.h"
#import <VKSdk/VKSdk.h>
#import "IVUser.h"

@interface IVServerManager() {
    NSMutableArray* friendsArray;
    NSDictionary* responseDict;
    NSArray* tempArrayForResponse;
}
@end

@implementation IVServerManager

+ (IVServerManager*) sharedManager {
    
    static IVServerManager* manager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[IVServerManager alloc] init];
    });
    
    return manager;
}

- (id)init
{
    self = [super init];
    if (self) {
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [VKSdk initializeWithDelegate:self andAppId:@"5086258"];
            if ([VKSdk wakeUpSession])
            {
                //Start working
            }
            
            NSArray *scope = [NSArray arrayWithObjects:VK_PER_WALL, VK_PER_MESSAGES, nil];
            [VKSdk authorize:scope revokeAccess:YES];
            //NSLog(@"authorized");
            
            //[[NSNotificationCenter defaultCenter] postNotificationName: @"iv.authorized" object: tempArrayForResponse];
            [self getFriendsFromServer];
            //NSLog(@"init %d", [_arrayOfFriends count]);
            
        });

        friendsArray = [NSMutableArray array];
    }
    return self;
}

- (void) sendMessage: (NSString* ) message toFriendWithFriendID: (NSNumber* ) friendID {
    
    
    NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                            friendID,  @"user_id",
                                                                            message,   @"message",
                                                                            @(5.37),   @"version",
                                                                            nil];
    
    VKRequest* msgReq = [VKRequest requestWithMethod:@"https://api.vk.com/method/messages.send"
                                       andParameters:parameters
                                       andHttpMethod:@"GET"];
    
    [msgReq executeWithResultBlock:^(VKResponse * response) {
        //NSLog(@"Json result: %@", response.json);
    } errorBlock:^(NSError * error) {
        if (error.code != VK_API_ERROR) {
            [error.vkError.request repeat];
        } else {
            NSLog(@"VK error: %@", error);
        }
    }];
    
}

- (void) getFriendsFromServer {
    
    [self.arrayOfFriends removeAllObjects];
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        
       //NSLog(@"user_id: %@", [[VKSdk getAccessToken] userId]);
        
        NSDictionary* parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [[VKSdk getAccessToken] userId],         @"user_id",
                                    @"photo_100",                            @"fields",
                                    @"nom",                                  @"fields",
                                    @(5.37),                                 @"version",
                                    nil];
        
        
        VKRequest* getFriendsRequest = [VKRequest requestWithMethod:@"https://api.vk.com/method/friends.get"
                                                      andParameters:parameters
                                                      andHttpMethod:@"GET"];
        
        [getFriendsRequest executeWithResultBlock:^(VKResponse * response) {
            
            //NSLog(@"Json result: %@\n(((((((((((((((((((((((((((((((((((", response.json);
            responseDict = [response.json objectForKey: @"items"];
            //tempArrayForResponse = [NSArray array];
            //tempArrayForResponse = [response.json objectForKey:@"items"];
            NSArray* dictsArray = [response.json objectForKey:@"items"];
            
            //NSLog(@"\n\n\n\n\nASDADSDAsDAs\n %@\n()()()(()()()()", dictsArray);
            
            
            [self configureFriendsArrayWithServerResponse: dictsArray];
        } errorBlock:^(NSError * error) {
            if (error.code != VK_API_ERROR) {
                [error.vkError.request repeat];
            } else {
                NSLog(@"VK error: %@", error);
            }
        }];
        
        
            });
    //NSLog(@"\n\n\n\nARRAY COUNT()()()()(\n%d", [_arrayOfFriends count]);
    
}

- (void) configureFriendsArrayWithServerResponse: (NSArray*) responseAsArray {
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        
        //NSDictionary* friendsDict = [response objectForKey: @"items"];
        //NSLog(@"%@", responseAsArray);
        [friendsArray removeAllObjects];
        
        IVUser* user = [[IVUser alloc] init];
        
        user.idOfUser = [(NSDictionary*)[responseAsArray firstObject] objectForKey: @"id"];
        user.firstName = [[responseAsArray firstObject] objectForKey: @"first_name"];
        user.lastName = [[responseAsArray firstObject] objectForKey: @"last_name"];
        user.photo = [[responseAsArray firstObject] objectForKey: @"fields"];
        
        //NSLog(@"%@", user.idOfUser);
        
        for (NSDictionary* dict in responseAsArray) {
            
            IVUser* user = [[IVUser alloc] init];
            
            user.idOfUser = [dict objectForKey: @"id"];
            user.firstName = [dict objectForKey: @"first_name"];
            user.lastName = [dict objectForKey: @"last_name"];
            user.photo = [dict objectForKey: @"photo_100"];
            user.isOnline = [dict objectForKey: @"online"];
            //NSLog(@"%@ %@", user.firstName, user.lastName);
            [self saveOrLoadPictureOfFriendWithID: user.idOfUser andPhoto: user.photo];
            
            [friendsArray addObject: user];
        }
        
        [self.arrayOfFriends removeAllObjects];
        self.arrayOfFriends = [NSMutableArray arrayWithArray: friendsArray];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: @"iv.setProperty" object: nil];
        NSLog(@"notification posted");
    });
    
}

- (void) saveOrLoadPictureOfFriendWithID: (NSNumber*) friendID andPhoto: (NSString*) photo {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        IVUser* user = [[IVUser alloc] init];
        
        NSString* idOfUserKey = [NSString stringWithFormat: @"%@", user.idOfUser];
        
        if (![user.photo isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey: idOfUserKey]]) {
            
            NSURL *imgUrl = [NSURL URLWithString: user.photo];
            NSData *data = [NSData dataWithContentsOfURL: imgUrl];
            UIImage *img = [[UIImage alloc] initWithData: data];
            user.img = img;
            [[NSUserDefaults standardUserDefaults] setObject: user.photo forKey: idOfUserKey];
            NSString * documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            [UIImageJPEGRepresentation(img, 1.0) writeToFile:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", idOfUserKey, @"jpg"]] options:NSAtomicWrite error:nil];
            
        }

    });
    }

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - VKSkdDelegate

- (void)vkSdkNeedCaptchaEnter:(VKError *)captchaError {
    }


- (void)vkSdkTokenHasExpired:(VKAccessToken *)expiredToken {
    
}

- (void)vkSdkUserDeniedAccess:(VKError *)authorizationError {
   
}
- (void)vkSdkShouldPresentViewController:(UIViewController *)controller {
   
}
- (void)vkSdkReceivedNewToken:(VKAccessToken *)newToken {
    
    //NSLog(@"%@", [newToken description]);
}


@end
