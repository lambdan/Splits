//
//  Browser.mm
//  Splits
//
//  Created by Edward Waller on 10/17/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#include "Browser.h"

Browser::Browser(WebView *web_view) : _load_completed(false) {
    _web_view = web_view;
}

void Browser::LoadHTML() {
    _load_completed = false;
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:@"splits" ofType:@"html" inDirectory:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    //[_web_view loadHTMLString:htmlString baseURL: [[NSBundle mainBundle] bundleURL]];
    //[[_web_view mainFrame] loadHTMLString:[[NSString alloc] initWithUTF8String:&html[0]] baseURL:nil]; // original
    //NSString *path = [[NSBundle mainBundle] bundlePath :inDirectory:@"html"];
    NSURL *baseUrl = [NSURL fileURLWithPath: htmlFile]; // set base url for css, js
    [[_web_view mainFrame] loadHTMLString:htmlString baseURL:baseUrl];
    //[[_web_view mainFrame] fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"splits" ofType:@"html" inDirectory:@"html"]];

}

void Browser::RunJavascript(std::string javascript) {
    //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"jquery" ofType:@"js" inDirectory:@"html"];
    //NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    //NSString *jsString = [[NSMutableString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
    //[webView stringByEvaluatingJavaScriptFromString:jsString];
    [[_web_view windowScriptObject] evaluateWebScript:[[NSString alloc] initWithUTF8String:&javascript[0]]];
    //[[_web_view windowScriptObject] evaluateWebScript:jsString];
}

bool Browser::IsLoadCompleted() {
    return _load_completed;
}

void Browser::set_load_completed(bool value) {
    _load_completed = value;
}
