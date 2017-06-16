//
//  WebBrowserInterface.h
//  SplitsCore
//
//  Created by Edward Waller on 10/17/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#ifndef __SplitsCore__WebBrowserInterface__
#define __SplitsCore__WebBrowserInterface__

#include <iostream>

class WebBrowserInterface
{
public:
    virtual void LoadHTML() = 0;
    virtual void RunJavascript(std::string javascript) = 0;
    virtual bool IsLoadCompleted() = 0;
};


#endif /* defined(__SplitsCore__WebBrowserInterface__) */
