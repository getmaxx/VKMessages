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
#import "IVMessageVCViewController.h";

@interface IVFriendsVC () {
    NSMutableArray* friends;
    NSMutableArray* arrayOfGroups;
    NSMutableArray* arrayOfTitles;
    NSMutableArray* arrayOfPhotos;
    //NSMutableArray* sortedFriends;
}

@end

static NSString* const kCharachters = @"АБВГДЕЖЗИКЛМНОПРСТУФХЦЧШЩЭЮЯABCDEFGHIJKLMNOPQRSTUVWXYZ";

@implementation IVFriendsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    dispatch_sync(dispatch_get_global_queue(0, 0), ^{
        [IVServerManager sharedManager];

    });
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(configureFriendsArray)
                                                 name: @"iv.setProperty"
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(reloadData)
                                                 name: @"iv.friendsSetUp"
                                               object: nil];

    /*[[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(getFriendsFromServer)
                                                 name: @"iv.friendsSetUp"
                                               object: nil];*/

    
}

- (void) reloadData {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"reload data");
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
        
        //NSLog(@"FINAL %d", [friends count]);

    });
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [arrayOfTitles count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSString* title = [arrayOfTitles objectAtIndex: section];
    return title;
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    //NSLog(@"%d", [(NSMutableArray*)[arrayOfGroups objectAtIndex:section] count]);
    return [(NSMutableArray*)[arrayOfGroups objectAtIndex:section] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"friendCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if(cell) {
        NSMutableArray* currentGroup = [arrayOfGroups objectAtIndex: indexPath.section];
        IVUser* user = [[IVUser alloc] init];
        user = (IVUser*)[currentGroup objectAtIndex: indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat :@"%@ %@ %@", user.lastName,
                                                                       user.firstName,
                                                                       [user.isOnline isEqual: @1]? @"": @" "];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.text =[NSString stringWithFormat:@"%@", [user.isOnline isEqual: @1]? @"online": @" " ];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //cell.imageView.image = user.img;
        });
        
        
    }
    
    
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSMutableArray* currentGroup = [arrayOfGroups objectAtIndex: indexPath.section];
    IVUser* user = [[IVUser alloc] init];
    user = (IVUser*)[currentGroup objectAtIndex: indexPath.row];
    
    IVMessageVCViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"msg"];
    vc.friendToMessage = user;
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
/*- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    if ([[segue identifier] isEqualToString:@"msg"]) {
        NSLog(@"segue");
        IVMessageVCViewController* vc = [segue destinationViewController];
    }
}*/


@end
