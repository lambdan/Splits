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
    // Load settings
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DefaultAlwaysOnTop"] == YES) {
        [alwaysOnTopMenuItem setState:NSOnState];
    }
    
    _web_browser = std::shared_ptr<WebBrowserInterface>(new Browser(webView));
    _core_application = new CoreApplication(_web_browser, "");
    _textSize = 100;
    fileName = NULL;
    
    [window setBackgroundColor:[NSColor blackColor]];
    [webView setDrawsBackground:NO];

    [NSTimer scheduledTimerWithTimeInterval: 0.033 target: self selector:@selector(onTick:) userInfo: nil repeats:YES];
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
    
    if([openDlg runModal] == NSOKButton) {
        NSString *file = [[openDlg URL] path];
        _core_application->LoadSplits([file cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}


- (IBAction)save:(id)sender {
    if(fileName == NULL) {
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel setExtensionHidden:NO];
        [savePanel setAllowedFileTypes: [[NSArray alloc] initWithObjects:@"splits", nil]];
        long result = [savePanel runModal];
        if(result == NSOKButton) {
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
    if(result == NSOKButton) {
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
    
    if([openDlg runModal] == NSOKButton) {
        NSString *file = [[openDlg URL] path];
        fileName = NULL;
        _core_application->LoadWSplitSplits([file cStringUsingEncoding:NSUTF8StringEncoding]);
    }
}

- (IBAction)timerReset:(id)sender {
    _core_application->ResetTimer();
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

- (IBAction)edit:(id)sender {
    _core_application->Edit();
}


- (IBAction)OneDecimal:(id)sender {
    _core_application->SetOneDecimal();
}

- (IBAction)TwoDecimal:(id)sender {
    _core_application->SetTwoDecimal();
}

- (IBAction)ThreeDecimal:(id)sender {
    _core_application->SetThreeDecimal();
}

- (IBAction)NoDecimal:(id)sender {
    _core_application->SetNoDecimal();
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
    NSLog(message);
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
