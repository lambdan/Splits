//
//  CoreApplication.h
//  SplitsCore
//
//  Created by Edward Waller on 10/17/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#ifndef __SplitsCore__CoreApplication__
#define __SplitsCore__CoreApplication__

#include <iostream>
#include <vector>
#include "WebBrowserInterface.h"
#include "Timer.h"
#include "Split.h"

class CoreApplication
{
public:
    CoreApplication(std::shared_ptr<WebBrowserInterface> browser, std::string settings_file);
    std::shared_ptr<Timer> timer();
    void LoadSplits(std::string file);
    void LoadWSplitSplits(std::string file);
    void SaveSplits(std::string file);
    void SaveWSplitSplits(std::string file);
    void StartTimer();
    void PauseTimer();
    void ResumeTimer();
    void StopTimer();
    void ResetTimer();
    void SplitTimer();
    void ChangeSetting(std::string key, std::string value);
    void Update();
    bool CanStart();
    bool CanPause();
    bool CanSplit();
    bool CanReset();
    bool CanGoToNextSegment();
    bool CanGoToPreviousSegment();
    std::string DisplayMilliseconds(unsigned long milliseconds, bool includeMilliseconds);
private:
    void ReloadSplits();
    void UpdateSplits();
    std::shared_ptr<WebBrowserInterface> _browser;
    std::vector<std::shared_ptr<Split> > _splits;
    int _currentSplitIndex;
    std::string _settings_file;
    std::shared_ptr<Timer> _timer;
};

#endif /* defined(__SplitsCore__CoreApplication__) */
