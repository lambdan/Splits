//
//  NewEditSplitsController.m
//  Splits
//
//  Created by djs on 2017-06-17.
//
//

#import "NewEditSplitsController.h"

@interface NewEditSplitsController ()
@property (assign) IBOutlet NSTableView *splitsTable;


@end

@implementation NewEditSplitsController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"opened");
    // Do view setup here.
}

- (IBAction)addSegment:(NSButton *)sender {
    NSLog(@"add");
}

- (IBAction)removeSegment:(NSButton *)sender {
    NSLog(@"remove");
    /*
     NSMutableArray *splits = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentSplits"];
    [splits removeLastObject];
    [[NSUserDefaults standardUserDefaults] setObject:splits forKey:@"CurrentSplits"];
    [_splitsTable reloadData];
     */
}

/*
- (int)numberOfRowsInTableView:(NSTableView *)splitsTable
{
    return 5;
}
*/
@end
