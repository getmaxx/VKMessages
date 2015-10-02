//
//  IVFriendsVC.m
//  vk
//
//  Created by Игорь Веденеев on 29.09.15.
//  Copyright © 2015 Игорь Веденеев. All rights reserved.
//

#import "IVFriendsVC.h"
#import "IVServerManager.h"
#import "IVUser.h"
#import "IVMessageVCViewController.h"

@interface IVFriendsVC () <UISearchBarDelegate> {
    
    NSMutableArray* friends;
    NSMutableArray* arrayOfGroups;
    NSMutableArray* arrayOfTitles;
    NSMutableArray* arrayOfPhotos;
    
    NSMutableArray* filteredFriends;
    
    NSMutableArray* onlineFriends;
    NSMutableArray* onlineArrayOfGroups;
    NSMutableArray* onlineArrayOfTitles;
    
    NSMutableArray* sourceForTableView;
    
    BOOL isFiltered;
    
    UISegmentedControl *segmentedControl;
    int currentSegment;
}

@end

static NSString* const kCharachters = @"АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯABCDEFGHIJKLMNOPQRSTUVWXYZ";

@implementation IVFriendsVC

- (void) test {
    NSLog(@"ADDED NEW FRIEND");
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewDidLoad {
    
    [super viewDidLoad];
        
    currentSegment = 0;
    sourceForTableView = [NSMutableArray array];
    
    isFiltered = NO;
    self.searchBar.text = @"";
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [IVServerManager sharedManager];
        [self getAvatars];

    });
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(configureFriendsArray)
                                                 name: @"iv.setProperty"
                                               object: nil];
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(getAvatars)
                                                 name: @"iv.friendsSetUp"
                                               object: nil];
    
    //[self getAvatars];
    
}

- (void) setUpUI {
    
    UIBarButtonItem *addFriendButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                                     target: self
                                                                                     action: @selector(test)];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.rightBarButtonItem = addFriendButton;
    
    NSString* numberOfFriends = [NSString stringWithFormat:@"%d друзей", [friends count]];
    NSString* numberOfOnlineFriendsString = [NSString stringWithFormat:@"%d онлайн", [onlineFriends count]];
    
    //NSLog(@"ALL:%d  ONLINE:%d", [friends count], numberOfOnlineFriends);
    
    NSArray *segItemsArray = [NSArray arrayWithObjects: numberOfFriends, numberOfOnlineFriendsString, nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:segItemsArray];
    segmentedControl.frame = CGRectMake(0, 0, 260, 30);
    segmentedControl.selectedSegmentIndex = currentSegment;
    [segmentedControl addTarget: self
                         action: @selector(segmentedControlValueChanged:)
               forControlEvents: UIControlEventValueChanged];
    
    UIBarButtonItem *segmentedControlButtonItem = [[UIBarButtonItem alloc] initWithCustomView:(UIView *)segmentedControl];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *barArray = [NSArray arrayWithObjects: flexibleSpace, segmentedControlButtonItem, flexibleSpace, nil];
    self.navigationController.toolbar.tintColor = [UIColor grayColor];
    
    self.toolbarItems = barArray;

}

- (void) segmentedControlValueChanged: (id) sender {
   
    currentSegment = segmentedControl.selectedSegmentIndex;
    self.searchBar.text = @"";
   [onlineFriends removeAllObjects];
    [filteredFriends removeAllObjects];
    
    if (segmentedControl.selectedSegmentIndex == 1) {
        dispatch_sync(dispatch_get_global_queue(0, 0), ^{
            [[IVServerManager sharedManager] getFriendsFromServer];
            [self getAvatars];
            [self configureOnlineFriendsArray];
            
            //sourceForTableView = onlineFriends;
            
        });
            //NSLog(@"1. online count %d", [onlineFriends count]);
            }
        else {
            dispatch_sync(dispatch_get_global_queue(0, 0), ^{
                [[IVServerManager sharedManager] getFriendsFromServer];
                [self getAvatars];
                [self configureFriendsArray];
                
                //sourceForTableView = friends;
                
            });

            //NSLog(@"all");
        }
    //NSLog(@"2. online count %d", [onlineFriends count]);
    [self reloadData];
}

- (void) getAvatars {
    
    //NSLog(@"aa");
    //[self reloadData];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //IVUser* user = [[IVUser alloc] init];
        
        for (IVUser* user in friends) {
            NSString* idOfUserKey = [NSString stringWithFormat: @"%@", user.idOfUser];
            
            if (![user.photo isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey: idOfUserKey]]) {
                
                NSURL *imgUrl = [NSURL URLWithString: user.photo];
                NSData *data = [NSData dataWithContentsOfURL: imgUrl];
                UIImage *img = [[UIImage alloc] initWithData: data];
                user.img = img;
                [[NSUserDefaults standardUserDefaults] setObject: user.photo forKey: idOfUserKey];
                NSString * documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                [UIImageJPEGRepresentation(img, 1.0) writeToFile:[documentsDirectory
                                                                  stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@", idOfUserKey, @"jpg"]]
                                                         options: NSAtomicWrite error:nil];
                
            }

        }
        
        
    });
    
    [self reloadData];
    
}

- (void) reloadData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"reload data");
        [self.tableView reloadData];
    });

}

- (void) configureFriendsArray {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        arrayOfGroups = [NSMutableArray array];
        arrayOfTitles = [NSMutableArray array];
        arrayOfPhotos = [NSMutableArray array];
        //sourceForTableView = friends;
        
        friends = [NSMutableArray arrayWithArray: [IVServerManager sharedManager].arrayOfFriends];
        NSArray *sortedFriends = [friends sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending: true]]];
        [friends removeAllObjects];
        friends = [NSMutableArray arrayWithArray: sortedFriends];
        
        for (int i = 0; i < [kCharachters length]; i++) {
            
            NSMutableArray* group = [NSMutableArray array];
            
            for (IVUser* user in sortedFriends) {
                
                if ([[user.lastName substringWithRange: NSMakeRange(0, 1)] isEqualToString: [kCharachters substringWithRange: NSMakeRange(i, 1)]]) {
                    [group addObject: user];
                }
                
            }
            
            if ([group count] != 0) {
                [arrayOfGroups addObject: group];
                [arrayOfTitles addObject: [kCharachters substringWithRange: NSMakeRange(i, 1)]];
            }
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"iv.friendsSetUp" object:nil];
        
        [self configureOnlineFriendsArray];
        
        [self setUpUI];
    });
    
   
}

- (void) configureFilteredFriendsArray {
    
    NSArray* source = [NSArray array];
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        source = friends;
    } else {
        source = onlineFriends;
    }
    
    filteredFriends = [NSMutableArray array];
    NSString* filter = [NSString stringWithString: self.searchBar.text];
    
    for (IVUser* user in source) {
        NSString* firstAndLastNames = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        if ([user.firstName containsString: filter] || [user.lastName containsString: filter] || [firstAndLastNames containsString: filter]) {
            [filteredFriends addObject: user];
            //NSLog(@"%@ %@", user.firstName, user.lastName);
        }
    }
    NSLog(@"\n");
    
}

- (void) configureOnlineFriendsArray {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [onlineFriends removeAllObjects];
        onlineArrayOfTitles = [NSMutableArray array];
        onlineArrayOfGroups = [NSMutableArray array];

        
        for (IVUser* user in friends) {
            if ([user.isOnline isEqual: @1]) {
                [onlineFriends addObject: user];
            }
        }
        
        NSArray *sortedFriends = [onlineFriends sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending: true]]];
        [onlineFriends removeAllObjects];
        onlineFriends = [NSMutableArray arrayWithArray: sortedFriends];
        
        for (int i = 0; i < [kCharachters length]; i++) {
            
            NSMutableArray* group = [NSMutableArray array];
            
            for (IVUser* user in sortedFriends) {
                
                if ([[user.lastName substringWithRange: NSMakeRange(0, 1)] isEqualToString: [kCharachters substringWithRange: NSMakeRange(i, 1)]]) {
                    [group addObject: user];
                }
                
            }
            
            if ([group count] != 0) {
                [onlineArrayOfGroups addObject: group];
                [onlineArrayOfTitles addObject: [kCharachters substringWithRange: NSMakeRange(i, 1)]];
            }
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"iv.friendsSetUp" object:nil];
        NSLog(@"online %d, groups %d", [onlineFriends count], [onlineArrayOfGroups count]);
        
        [self setUpUI];
    });

    
    
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [super touchesBegan:touches withEvent:event];
    [self.searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    
    NSArray* source = [NSArray array];
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        source = arrayOfTitles;
    } else {
        source = onlineArrayOfTitles;
    }
    
    //NSLog(@"sections: %d", [source count]);
    
    if (!isFiltered) {
        return [source count];
    }
    else {
        return 1;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSArray* source = [NSArray array];

    if (segmentedControl.selectedSegmentIndex == 0) {
        source = arrayOfTitles;
    } else {
        source = onlineArrayOfTitles;
    }
    
    NSString* title = [source objectAtIndex: section];
    if (!isFiltered) {
        return title;

    }
    else {
        return @"Найдены";
    }

    
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSArray* source = [NSArray array];
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        source = arrayOfGroups;
    } else {
        source = onlineArrayOfGroups;
    }

    if (!isFiltered) {
        return [(NSMutableArray*)[source objectAtIndex:section] count];
    }
    else {
        return [filteredFriends count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if(cell) {
        IVUser* user = [[IVUser alloc] init];
        
        NSArray* source = [NSArray array];
        
        if (segmentedControl.selectedSegmentIndex == 0) {
            source = arrayOfGroups;
        } else {
            source = onlineArrayOfGroups;
        }


        if (!isFiltered) {
            NSMutableArray* currentGroup = [source objectAtIndex: indexPath.section];
            user = (IVUser*)[currentGroup objectAtIndex: indexPath.row];

        }
        else {
            user = (IVUser*)[filteredFriends objectAtIndex: indexPath.row];
        }
        
        cell.textLabel.text = [NSString stringWithFormat :@"%@ %@ %@", user.lastName,
                                                                       user.firstName,
                                                                       [user.isOnline isEqual: @1]? @"*": @" "];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.text =[NSString stringWithFormat:@"%@", [user.isOnline isEqual: @1]? @"online": @" " ];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        
        NSString * documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        UIImage * result = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@.%@", documentsDirectory, user.idOfUser, @"jpg"]];
        cell.imageView.image = result;
        
    }
    
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self searchBarCancelButtonClicked: self.searchBar];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray* source = [NSArray array];
    
    if (segmentedControl.selectedSegmentIndex == 0) {
        source = arrayOfGroups;
    } else {
        source = onlineArrayOfGroups;
    }

    
    NSMutableArray* currentGroup = [source objectAtIndex: indexPath.section];
    IVUser* user = [[IVUser alloc] init];
    user = (IVUser*)[currentGroup objectAtIndex: indexPath.row];
    
    IVMessageVCViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"msg"];
    vc.friendToMessage = user;
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar setShowsCancelButton: NO animated: YES];
    [self.searchBar resignFirstResponder];
}

#pragma mark - UISearchBarDelegate

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //isFiltered = YES;
    [searchBar setShowsCancelButton: YES animated: YES];
    
    if (![searchBar.text isEqualToString: @""]) {
        isFiltered = YES;
        [self configureFilteredFriendsArray];
        [self.tableView reloadData];
    }

}

- (void) searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar setShowsCancelButton: NO animated: YES];
    [searchBar resignFirstResponder];
    isFiltered = NO;
    [self.tableView reloadData];

}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    
    if (![searchBar.text isEqualToString: @""]) {
        isFiltered = YES;
        [self configureFilteredFriendsArray];
        [self.tableView reloadData];
    }
    else {
        isFiltered = NO;
        [self.tableView reloadData];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
