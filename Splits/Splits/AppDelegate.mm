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
    NSMutableArray *splits_placeholder = [[NSMutableArray alloc] initWithCapacity:99];
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
    [[NSUserDefaults standardUserDefaults] synchronize];
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
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [window setBackgroundColor:[NSColor blackColor]];
    [webView setDrawsBackground:NO];
    //[window setStyleMask:NSBorderlessWindowMask]; // hides title bar, but cant move window then :(
    
    _titleBarShown = true;
    
    [NSTimer scheduledTimerWithTimeInterval: 0.033 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
    

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
    NSLog(@"NSNotificationCenter: updating attempts to %ld", updatedAttempts);
    _core_application->UpdateEdittedSplits([updatedTitle UTF8String], updatedAttempts);
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


-(void)onTick:(NSTimer *)timer {
    _core_application->Update();
    [self updateDisplay];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    
}

- (IBAction)timerStart:(id)sender {
    _core_application->StartTimer();
}

- (IBAction)timerSplit:(id)sender {
    _core_application->SplitTimer();
}

- (IBAction)openDocument:(id)sender {
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
        NSMutableArray *splitNamesArray = [names componentsSeparatedByString:@"🐊"];
        [splitNamesArray removeLastObject]; // remove last entry as it will be empty
        NSMutableArray *splitTimesArray = [times componentsSeparatedByString:@"🐊"];
        [splitTimesArray removeLastObject];
        
        // Merge the two arrays into one with keys
        NSMutableArray *splits = [NSMutableArray array];
        for (NSUInteger i = 0; i < splitNamesArray.count; i++) {
            [splits addObject: @{@"name" : splitNamesArray[i], @"time" : splitTimesArray[i]}];
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
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
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

- (IBAction)importWSplitFile:(id)sender {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setExtensionHidden:NO];
    
    [openDlg setCanChooseFiles:YES];
    [openDlg setAllowsMultipleSelection:NO];
    [openDlg setCanChooseDirectories:NO];
    
    if([openDlg runModal] == NSModalResponseOK) {
        NSString *file = [[openDlg URL] path];
        fileName = NULL;
        _core_application->LoadWSplitSplits([file cStringUsingEncoding:NSUTF8StringEncoding]);
        NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        NSLog(@"importWSplit: ReturnAttempts reports %i", attempts);
        
        
        // Update NSUserDefaults with title, attempts and splits so we can edit them
        //NSString *title = [NSString stringWithUTF8String:_core_application->ReturnTitle().c_str()];
        [[NSUserDefaults standardUserDefaults] setObject:title forKey:@"CurrentTitle"];
        
        //NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
        [[NSUserDefaults standardUserDefaults] setInteger:attempts forKey:@"CurrentAttempts"];
        NSLog(@"importWSplit attempts :%ld", attempts);
        

        [[NSUserDefaults standardUserDefaults] synchronize];
        
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
    _core_application->ResetTimer();
    NSInteger attempts = (NSInteger) _core_application->ReturnAttempts();
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
    
    [[NSUserDefaults standardUserDefaults] synchronize];
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
