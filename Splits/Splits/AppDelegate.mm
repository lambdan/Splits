//
//  AppDelegate.m
//  Splits
//
//  Created by Edward Waller on 10/15/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#import "AppDelegate.h"
#import <WebKit/WebKit.h>
#include "Browser.h"

@implementation AppDelegate


@synthesize window;
@synthesize webView;
@synthesize startMenuItem;
@synthesize alwaysOnTopMenuItem;
@synthesize fileName;

- (void)dealloc {
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Initialize default settings
    //NSMutableArray *currentSplitsArray = [[[NSUserDefaults standardUserDefaults] arrayForKey:@"YourKey"] mutableCopy];
    NSMutableArray *splits_placeholder = [[NSMutableArray alloc] init];
    //_splits_current_times = [[NSMutableArray alloc] init];
    NSMutableDictionary *defaultsDict = [@{
                                           @"DefaultAlwaysOnTop":@YES,
                                           @"DecimalsToShow":@3,
                                           @"ShowTitle":@TRUE,
                                           @"ShowAttempts":@FALSE,
                                           @"CurrentTitle":@"",
                                           @"CurrentAttempts":@0,
                                           @"CurrentSplits":splits_placeholder
                                           } mutableCopy];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultsDict];
    /// --------------------
    
    _web_browser = std::shared_ptr<WebBrowserInterface>(new Browser(webView));
    _core_application = new CoreApplication(_web_browser, "");
    _textSize = 100;
    fileName = NULL;
    
    
    if (_core_application->ReturnSplitsLoaded() == false) {
        // Clear leftovers from last run
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"CurrentTitle"];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"CurrentAttempts"];
        [[NSUserDefaults standardUserDefaults] setObject:splits_placeholder forKey:@"CurrentSplits"];
    }
    
    [window setBackgroundColor:[NSColor blackColor]];
    [webView setDrawsBackground:NO];
    //[window setStyleMask:NSBorderlessWindowMask]; // hides title bar, but cant move window then :(
    
    _titleBarShown = true;
    
    [NSTimer scheduledTimerWithTimeInterval: 0.033 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
    
    _shouldUpdateSplits = true;

    // Load Always on Top-setting
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
        [alwaysOnTopMenuItem setState:NSOnState];
    }
    
    // Load decimals settings
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"DecimalsToShow"]) {
        case 0:
            _core_application->SetNoDecimal();
            break;
        case 1:
            _core_application->SetOneDecimal();
            break;
        case 2:
            _core_application->SetTwoDecimal();
            break;
        case 3:
            _core_application->SetThreeDecimal();
            break;
    }
    
    // Load title/attempts display preference
    switch ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTitle"]) {
        case true:
            _core_application->ShowRunTitle();
            break;
        case false:
            _core_application->NoRunTitle();
            break;
    }
    
    switch ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowAttempts"]) {
        case true:
            _core_application->ShowRunAttempts();
            break;
        case false:
            _core_application->NoRunAttempts();
            break;
    }
    
    // Add a watcher to detect changes to preferences...
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(defaultsChanged:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

}



- (void)defaultsChanged:(NSNotification *)notification { // Detects changes to preferences or splits (through New/Edit Splits menu) and updates
    NSLog(@"NSNotificationCenter: something has changed");
    // Load decimals settings
    switch ([[NSUserDefaults standardUserDefaults] integerForKey:@"DecimalsToShow"]) {
        case 0:
            _core_application->SetNoDecimal();
            break;
        case 1:
            _core_application->SetOneDecimal();
            break;
        case 2:
            _core_application->SetTwoDecimal();
            break;
        case 3:
            _core_application->SetThreeDecimal();
            break;
    }
    
    // Load title/attempts display settings
    switch ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTitle"]) {
        case true:
            _core_application->ShowRunTitle();
            break;
        case false:
            _core_application->NoRunTitle();
            break;
    }
    
    switch ([[NSUserDefaults standardUserDefaults] boolForKey:@"ShowAttempts"]) {
        case true:
            _core_application->ShowRunAttempts();
            break;
        case false:
            _core_application->NoRunAttempts();
            break;
    }
    
    
    NSString *updatedTitle = [[NSUserDefaults standardUserDefaults] stringForKey:@"CurrentTitle"];
    NSInteger updatedAttempts = (NSInteger) [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentAttempts"];
    
    NSInteger split_count = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentSplits"] count];

    NSLog(@"NSNotificationCenter: updating attempts to %ld", updatedAttempts);
    
    NSString *split_names = [[ [ [ NSUserDefaults standardUserDefaults] objectForKey:@"CurrentSplits"] valueForKey:@"name"] componentsJoinedByString:@"@"];
    
    NSMutableArray *stored_times = [[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentSplits"] valueForKey:@"time"];
    NSMutableArray *times = [[NSMutableArray alloc] init];
    // Convert hh:mm:ss.xxx to ms
    for (NSUInteger i = 0; i < stored_times.count; i++) {
        NSString *timeFormatted = [stored_times objectAtIndex:i];
        NSUInteger timeInMs = [self HHMMSSXXXtoMS:timeFormatted];
        [times addObject:[NSString stringWithFormat:@"%d", timeInMs]];
    }

    // Combine times array into one string that can be sent to SplitsCore
    NSString *split_times = [times componentsJoinedByString:@"@"];
    
    NSLog(@"NSNotificationCenterSending this string to SplitsCore: %@", split_times);
    
    if (_shouldUpdateSplits == true) {
        _core_application->UpdateEdittedSplits([updatedTitle UTF8String], updatedAttempts, split_count, [split_names UTF8String], [split_times UTF8String]);
        _shouldUpdateSplits = true;
    } else {
        NSLog(@"_shouldUpdateSplits: Splits prevented from being updated");
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize]; // this gets executed whenever anything changes, so it should only be executed here
    
}


-(void)onTick:(NSTimer *)timer {
    _core_application->Update();
    [self updateDisplay];
}

- (NSString*)msToHHMMSSXXX:(NSString*) inputTime {
    NSLog(@"msToHHMSSXXX: received %@", inputTime);
    
    NSUInteger millis = [inputTime intValue];
    NSUInteger s = (millis/1000) % 60;
    NSUInteger m = (millis/ (1000*60)) % 60;
    NSUInteger h = (millis/ (1000*60*60)) % 24;
    NSUInteger ms = (millis % 1000);
    //NSLog(@"%i %i %i %i", h,m,s,ms);
    return [NSString stringWithFormat:@"%02d:%02d:%02d.%03d", h,m,s,ms];
}

- (NSUInteger)HHMMSSXXXtoMS:(NSString*) inputTime {
    NSLog(@"HHMMSSXXXtoMS: received %@", inputTime);
    NSArray *components = [inputTime componentsSeparatedByString:@":"];
    NSArray *secComponents = [components[2] componentsSeparatedByString:@"."];
    
    NSUInteger h = [components[0] intValue];
    NSUInteger m = [components[1] intValue];
    NSUInteger s = [secComponents[0] intValue];
    NSUInteger ms = [secComponents[1] intValue];
    
    ms += s*1000;
    ms += (m*1000*60);
    ms += (h*1000*60*60);
    
    //NSLog(@"HHMMSSXXXtoMS: converted %@ to %d", inputTime, ms);
    NSLog(@"HHMMSSXXXtoMS: returning %lu", ms);
    return ms;
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    
}

- (IBAction)timerStart:(id)sender {
    _shouldUpdateSplits = false;
    _core_application->StartTimer();
}

- (IBAction)timerSplit:(id)sender {
    _shouldUpdateSplits = false;
    _core_application->SplitTimer(); // Send split command
    NSInteger splitIndex = (NSInteger) _core_application->ReturnSplitIndex() - 1;
    NSInteger currentTime = (NSInteger) _core_application->ReturnCurrentTime();
    
    if (splitIndex >= 0) {
        NSLog(@"Split: adding current time %i to index %i", currentTime, splitIndex);
        [_splits_current_times setObject:@(currentTime) atIndex:splitIndex];
    }
    
    NSLog(@"Split: split_current_times %@", _splits_current_times);
    
    if (_core_application->ReturnRunFinished() == true) {
        NSLog(@"!!!!!!!!!!!!!!!! Run finished !!!!!!!!!!!!!!!");
        
        // Check if PB
        NSString *times = [NSString stringWithUTF8String:_core_application->ReturnSplitTimes().c_str()];
        NSMutableArray *loadedTimes = [[times componentsSeparatedByString:@"@"] mutableCopy];
        [loadedTimes removeLastObject];
        NSInteger oldPB = [(NSInteger) [loadedTimes lastObject] intValue];
        NSLog(@"old pb: %i", oldPB);
        
        NSInteger thisRunsTime = [(NSInteger) [_splits_current_times lastObject] intValue];
        NSLog(@"new pb: %i", thisRunsTime);
        
        if (thisRunsTime < oldPB || oldPB == 0) {
            // This run was better, save it
            NSLog(@"NEW PB!");
            NSString *names = [NSString stringWithUTF8String:_core_application->ReturnSplitNames().c_str()];
            NSLog(@"RunFinished: Got Split Names: %@", names);
            NSLog(@"RunFinished: Got Split Times: %@", _splits_current_times);
            
            // Convert strings separated by crocodiles to array with split names
            NSMutableArray *splitNamesArray = [[names componentsSeparatedByString:@"@"] mutableCopy];
            [splitNamesArray removeLastObject]; // remove last entry as it will be empty
            NSMutableArray *splitTimesArray = _splits_current_times;
            
            // Merge the two arrays into one with keys
            NSMutableArray *splits = [NSMutableArray array];
            for (NSUInteger i = 0; i < splitNamesArray.count; i++) {
                // Convert ms to hhmmss
                NSString *formattedTime = [self msToHHMMSSXXX:splitTimesArray[i] ];
                NSLog(@"RunFinsihed: formatted time: %s", formattedTime);
                [splits addObject: @{@"name" : splitNamesArray[i], @"time" : formattedTime}];
            }
            //NSLog(@"splits length: %i", splits.count);
            
            // Update userdefaults
            _shouldUpdateSplits = false; // So we get to see our deltas, when we reset it will be updated instead
            [[NSUserDefaults standardUserDefaults] setObject:splits forKey:@"CurrentSplits"];
        } else {
            NSLog(@"Run finished, but no PB :(");
        }
    }
}

- (IBAction)openDocument:(id)sender {
    // Close and unload old splits
    _core_application->CloseSplitsToTimer();
    NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
    NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
    [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];
    [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
    //NSMutableArray *splits_placeholder = [[NSMutableArray alloc] init];
    [[NSUserDefaults standardUserDefaults] setObject:_splits_current_times forKey:@"CurrentSplits"];
    // ---------------------------------------------------- //
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"splits", nil]];
    [openDlg setExtensionHidden:NO];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    
    if([openDlg runModal] == NSModalResponseOK) {
        NSString *file = [[openDlg URL] path];
        _core_application->LoadSplits([file cStringUsingEncoding:NSUTF8StringEncoding]);
        NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        NSLog(@"openDocument: ReturnAttempts reports %i", attempts);
        
        // splits logic here (key name: CurrentSplitNames and CurrentSplitTimes
        NSString *names = [NSString stringWithUTF8String:_core_application->ReturnSplitNames().c_str()];
        NSString *times = [NSString stringWithUTF8String:_core_application->ReturnSplitTimes().c_str()];
        NSLog(@"openDocument: Got Split Names:");
        NSLog(names);
        NSLog(@"openDocument: Got Split Times:");
        NSLog(times);
        // Convert strings separated by crocodiles to array with split names
        NSMutableArray *splitNamesArray = [[names componentsSeparatedByString:@"@"] mutableCopy];
        [splitNamesArray removeLastObject]; // remove last entry as it will be empty
        NSMutableArray *splitTimesArray = [[times componentsSeparatedByString:@"@"] mutableCopy];
        [splitTimesArray removeLastObject];
        
        // Merge the two arrays into one with keys
        NSMutableArray *splits = [NSMutableArray array];
        for (NSUInteger i = 0; i < splitNamesArray.count; i++) {
            // Convert ms to hhmmss
            NSString *formattedTime = [self msToHHMMSSXXX:splitTimesArray[i] ];
            NSLog(@"formatted time: %s", formattedTime);
            [splits addObject: @{@"name" : splitNamesArray[i], @"time" : formattedTime}];
        }
        //NSLog(@"splits length: %i", splits.count);
        
        // Update userdefaults
        [[NSUserDefaults standardUserDefaults] setObject:splits forKey:@"CurrentSplits"];
        
        
        // Update NSUserDefaults with title, attempts and splits so we can edit them
        //NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];
        
        //NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
        NSLog(@"attempts :%ld", attempts);
        
    }
}


- (IBAction)save:(id)sender {
    if(fileName == NULL) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel setExtensionHidden:NO];
        [savePanel setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"splits", nil]];
        long result = [savePanel runModal];
        if(result == NSModalResponseOK) {
            [fileName release];
            fileName = [NSString stringWithString:[[savePanel URL] path]];;
            [fileName retain];
        } else {
            return;
        }
    }
    _core_application->SaveSplits([fileName cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (IBAction)saveAs:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"splits", nil]];
    long result = [savePanel runModal];
    if(result == NSModalResponseOK) {
        [fileName release];
        fileName = [NSString stringWithString:[[savePanel URL] path]];;
        [fileName retain];
        _core_application->SaveSplits([fileName cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (IBAction)exportWsplit:(id)sender {
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setExtensionHidden:NO];
    [savePanel setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"wsplit", nil]];
    long result = [savePanel runModal];
    if(result == NSModalResponseOK) {
        [fileName release];
        fileName = [NSString stringWithString:[[savePanel URL] path]];;
        [fileName retain];
        _core_application->SaveWSplitSplits([fileName cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (IBAction)importWSplitFile:(id)sender {
    // Close and unload old splits
    _core_application->CloseSplitsToTimer();
    NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
    NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
    [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];
    [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
    //NSMutableArray *splits_placeholder = [NSMutableArray init];
    [[NSUserDefaults standardUserDefaults] setObject:_splits_current_times forKey:@"CurrentSplits"];
    // ---------------------------------------------------- //
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"wsplit", nil]];
    [openDlg setExtensionHidden:NO];
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    
    if([openDlg runModal] == NSModalResponseOK) {
        NSString *file = [[openDlg URL] path];
        _core_application->LoadWSplitSplits([file cStringUsingEncoding:NSUTF8StringEncoding]);
        NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        NSLog(@"openDocument: ReturnAttempts reports %i", attempts);
        
        // splits logic here (key name: CurrentSplitNames and CurrentSplitTimes
        NSString *names = [NSString stringWithUTF8String:_core_application->ReturnSplitNames().c_str()];
        NSString *times = [NSString stringWithUTF8String:_core_application->ReturnSplitTimes().c_str()];
        NSLog(@"openDocument: Got Split Names:");
        NSLog(names);
        NSLog(@"openDocument: Got Split Times:");
        NSLog(times);
        // Convert strings separated by crocodiles to array with split names
        NSMutableArray *splitNamesArray = [[names componentsSeparatedByString:@"@"] mutableCopy];
        [splitNamesArray removeLastObject]; // remove last entry as it will be empty
        NSMutableArray *splitTimesArray = [[times componentsSeparatedByString:@"@"] mutableCopy];
        [splitTimesArray removeLastObject];
        
        // Merge the two arrays into one with keys
        NSMutableArray *splits = [NSMutableArray array];
        for (NSUInteger i = 0; i < splitNamesArray.count; i++) {
            // Convert ms to hhmmss
            NSString *formattedTime = [self msToHHMMSSXXX:splitTimesArray[i] ];
            NSLog(@"formatted time: %s", formattedTime);
            [splits addObject: @{@"name" : splitNamesArray[i], @"time" : formattedTime}];
        }
        //NSLog(@"splits length: %i", splits.count);
        
        // Update userdefaults
        [[NSUserDefaults standardUserDefaults] setObject:splits forKey:@"CurrentSplits"];
        
        
        // Update NSUserDefaults with title, attempts and splits so we can edit them
        //NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];
        
        //NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
        NSLog(@"attempts :%ld", attempts);
        
    }
}

- (IBAction)preferencesButton:(id)sender {
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
    [windowController showWindow:self];
}

- (IBAction)newSplitsButton:(id)sender {
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"NewEditSplits"];
    [windowController showWindow:self];
    
    //NSArray *splits = [[NSUserDefaults standardUserDefaults] arrayForKey:@"CurrentSplits"];
}

- (IBAction)edit:(id)sender {
    NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"NewEditSplits"];
    [windowController showWindow:self];
    //_core_application->Edit();
}

- (IBAction)timerReset:(id)sender {
    _shouldUpdateSplits = true;
    _core_application->ResetTimer();
    NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
    _splits_current_times = [[NSMutableArray alloc] init];
    [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
    
}

- (IBAction)timerPause:(id)sender {
    _core_application->PauseTimer();
}


- (IBAction)timerPreviousSegment:(id)sender {
    _core_application->GoToPreviousSegment();
}

- (IBAction)timerNextSegment:(id)sender {
    _core_application->GoToNextSegment();
}

- (IBAction)zoomIn:(id)sender {
    _textSize += 5;
    NSString *adjustJS = [NSString stringWithFormat:@"$('body, table').css('font-size', '%d%%');", _textSize];
    _web_browser->RunJavascript([adjustJS cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (IBAction)zoomOut:(id)sender {
    _textSize -= 5;
    NSString *adjustJS = [NSString stringWithFormat:@"$('body, table').css('font-size', '%d%%');", _textSize];
    _web_browser->RunJavascript([adjustJS cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (IBAction)actualSize:(id)sender {
}

- (IBAction)alwaysOnTop:(id)sender {
    BOOL currentState = ([alwaysOnTopMenuItem state] == NSOnState);
    
    [[NSUserDefaults standardUserDefaults] setBool:!currentState forKey:@"DefaultAlwaysOnTop"];
    [alwaysOnTopMenuItem setState:currentState ? NSOffState : NSOnState];
}


- (IBAction)CloseSplitsToTimer:(id)sender {
    _core_application->CloseSplitsToTimer();
    NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
    NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
    
    [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];

    [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
    
    NSMutableArray *splits_placeholder = [[NSMutableArray alloc] init];
    [[NSUserDefaults standardUserDefaults] setObject:splits_placeholder forKey:@"CurrentSplits"];
    
}


- (IBAction)openHTMLFolder:(id)sender {
    // Open HTML Folder that is under Splits submenu, where css and html is contained
    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"splits" ofType:@"html" inDirectory:@"html"];
    [[NSWorkspace sharedWorkspace] openFile:[htmlPath stringByDeletingLastPathComponent]];
}

- (IBAction)toggleTitleBar:(id)sender {
    if (_titleBarShown == true) {
        [window setStyleMask:NSBorderlessWindowMask];
        _titleBarShown = false;
    } else if (_titleBarShown == false) {
        [window setStyleMask:[window styleMask] | NSResizableWindowMask | NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask];
        [window setTitle:@"Splits"];
        _titleBarShown = true;
    }
}

// - (BOOL)validateMenuItem:(NSMenuItem *)menuItem { // not sure if i need this. commented it out so i can hit Split before start - seems to work fine without it... leaving for now (DJS)
//    if([menuItem action] == @selector(timerStart:)) {
//        return _core_application->CanStart();
//    } else if([menuItem action] == @selector(timerPause:)) {
//        return _core_application->CanPause();
//    } else if([menuItem action] == @selector(timerSplit:)) {
//        return _core_application->CanSplit();
//    } else if([menuItem action] == @selector(timerReset:)) {
//        return _core_application->CanReset();
//    } else if([menuItem action] == @selector(timerPreviousSegment:)) {
//        return _core_application->CanGoToPreviousSegment();
//    } else if([menuItem action] == @selector(timerNextSegment:)) {
//        return _core_application->CanGoToNextSegment();
//    }
//    return YES;
//}

- (void)windowDidResize:(NSNotification *)notification {
    [self updateDisplay];
}

- (void)updateDisplay {
    NSSize size = [webView frame].size;
    NSString *s = [NSString stringWithFormat:@"var textareaWidth = $('#splits')[0].scrollWidth;$('#splits_container').height(%f - $('#timer').height());", size.height];
    if(_web_browser != NULL) {
        _web_browser->RunJavascript([s cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WebFrame *)frame {
    //NSLog(message);
}

- (void)windowDidResignMain:(NSNotification *)notification {
    // It's always nicer if the user has a choice
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
        [[self window] setLevel:NSFloatingWindowLevel];
    } else {
        [[self window] setLevel:NSNormalWindowLevel];
    }
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
    [[self window] setLevel:NSNormalWindowLevel];
}

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { // press X to quit
    return YES;
}

@end
