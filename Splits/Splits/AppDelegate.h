//
//  AppDelegate.h
//  Splits
//
//  Created by Edward Waller on 10/15/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#include <SplitsCore/CoreApplication.h>
#include <SplitsCore/WebBrowserInterface.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;
//@property (assign) IBOutlet NSMenuItem *OneDecimal;
//@property (assign) IBOutlet NSMenuItem *TwoDecimal;
//@property (assign) IBOutlet NSMenuItem *ThreeDecimal;
@property (assign) IBOutlet WebView *webView;
@property (assign) IBOutlet NSMenuItem *startMenuItem;
@property (assign) IBOutlet NSMenuItem *pauseMenuItem;
@property (assign) IBOutlet NSMenuItem *splitMenuItem;
@property (assign) IBOutlet NSMenuItem *resetMenuItem;
@property (assign) IBOutlet NSMenuItem *previousSegmentMenuItem;
@property (assign) IBOutlet NSMenuItem *nextSegmentMenuItem;
@property (assign) IBOutlet NSMenuItem *alwaysOnTopMenuItem;
@property (nonatomic, retain) NSString *fileName;
- (IBAction)timerStart:(id)sender;
- (IBAction)timerSplit:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)importWSplitFile:(id)sender;
- (IBAction)timerReset:(id)sender;
- (IBAction)timerPause:(id)sender;
- (IBAction)timerPreviousSegment:(id)sender;
- (IBAction)timerNextSegment:(id)sender;
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)actualSize:(id)sender;
- (IBAction)alwaysOnTop:(id)sender;
- (IBAction)edit:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)saveAs:(id)sender;

- (IBAction)OneDecimal:(id)sender; // bla
- (IBAction)TwoDecimal:(id)sender;
- (IBAction)ThreeDecimal:(id)sender;
- (IBAction)NoDecimal:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
- (void)windowDidResize:(NSNotification *)notification;
- (void)updateDisplay;

@end

CoreApplication *_core_application;
std::shared_ptr<WebBrowserInterface> _web_browser;
int _textSize;