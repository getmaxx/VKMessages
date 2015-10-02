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
    BOOL isFiltered;
}

@end

static NSString* const kCharachters = @"АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯABCDEFGHIJKLMNOPQRSTUVWXYZ";

@implementation IVFriendsVC

- (void) test {
    NSLog(@"ADDED NEW FRIEND");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.addButtonItem;
    
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

    /*[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(getFriendsFromServer)
                                                 name: @"iv.friendsSetUp"
                                               object: nil];*/
    
    [self getAvatars];
    
}

- (void) setUpUI {
    
    UIBarButtonItem *addFriendButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemAdd
                                                                                     target: self
                                                                                     action: @selector(test)];
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.rightBarButtonItem = addFriendButton;
    
    NSString* numberOfFriends = [NSString stringWithFormat:@"%d друзей", [friends count]];
    int numberOfOnlineFriends = 0;
    for (IVUser* user in friends) {
        if ([user.isOnline  isEqual: @1]) {
            numberOfOnlineFriends++;
        }
    }
    NSString* numberOfOnlineFriendsString = [NSString stringWithFormat:@"%d онлайн", numberOfOnlineFriendsString];
    
    NSLog(@"ALL:%d  ONLINE:%d", [friends count], numberOfOnlineFriends);
    
    NSArray *segItemsArray = [NSArray arrayWithObjects: numberOfFriends, onlineFriends, nil];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segItemsArray];
    segmentedControl.frame = CGRectMake(0, 0, 250, 30);
    segmentedControl.selectedSegmentIndex = 0;
    UIBarButtonItem *segmentedControlButtonItem = [[UIBarButtonItem alloc] initWithCustomView:(UIView *)segmentedControl];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    NSArray *barArray = [NSArray arrayWithObjects: flexibleSpace, segmentedControlButtonItem, flexibleSpace, nil];
    self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.barTintColor;
    
    self.toolbarItems = barArray;

}

- (void) getAvatars {
    
    [self reloadData];
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) configureFriendsArray {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        arrayOfGroups = [NSMutableArray array];
        arrayOfTitles = [NSMutableArray array];
        arrayOfPhotos = [NSMutableArray array];
        
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
        for (NSMutableArray* array in arrayOfGroups) {
            for (IVUser* user in array) {
                
                //[arrayOfPhotos addObject: img];
             
             }
            //NSLog(@"%d", [array count]);
        }
        
        //NSLog(@"FINAL %d", [arrayOfTitles count]);
        
         [self setUpUI];
    });
    
   
}

- (void) configureFilteredFriendsArray {
    
    filteredFriends = [NSMutableArray array];
    NSString* filter = [NSString stringWithString: self.searchBar.text];
    
    for (IVUser* user in friends) {
        NSString* firstAndLastNames = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        if ([user.firstName containsString: filter] || [user.lastName containsString: filter] || [firstAndLastNames containsString: filter]) {
            [filteredFriends addObject: user];
            NSLog(@"%@ %@", user.firstName, user.lastName);
        }
    }
    NSLog(@"\n");
    
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
    if (!isFiltered) {
        return [arrayOfTitles count];
    }
    else {
        return 1;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString* title = [arrayOfTitles objectAtIndex: section];
    if (!isFiltered) {
        return title;

    }
    else {
        return @"Найдены";
    }

    
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //NSLog(@"%d", [(NSMutableArray*)[arrayOfGroups objectAtIndex:section] count]);
    if (!isFiltered) {
        return [(NSMutableArray*)[arrayOfGroups objectAtIndex:section] count];
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

        if (!isFiltered) {
            NSMutableArray* currentGroup = [arrayOfGroups objectAtIndex: indexPath.section];
            user = (IVUser*)[currentGroup objectAtIndex: indexPath.row];

        }
        else {
            user = (IVUser*)[filteredFriends objectAtIndex: indexPath.row];
        }
        
        cell.textLabel.text = [NSString stringWithFormat :@"%@ %@ %@", user.lastName,
                                                                       user.firstName,
                                                                       [user.isOnline isEqual: @1]? @"": @" "];
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
    
    NSMutableArray* currentGroup = [arrayOfGroups objectAtIndex: indexPath.section];
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




@end
