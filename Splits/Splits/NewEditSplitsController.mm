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
    // Add a watcher to detect changes to preferences...
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

- (void)defaultsChanged:(NSNotification *)notification { // Detects changes to preferences or splits (through New/Edit Splits menu) and updates
    [_splitsTable reloadData];
}

- (IBAction)addSegment:(NSButton *)sender {
    //NSLog(@"add");
}

- (IBAction)removeSegment:(NSButton *)sender {
    //NSLog(@"remove");
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
