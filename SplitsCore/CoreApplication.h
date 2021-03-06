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
#include "Global.h"
#include "Split.h"



class CoreApplication
{
public:
    CoreApplication(std::shared_ptr<WebBrowserInterface> browser, std::string settings_file);
    std::shared_ptr<Timer> timer();
    //std::shared_ptr<Decimals> decimals();
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
    void GoToNextSegment();
    void GoToPreviousSegment();
    void ChangeSetting(std::string key, std::string value);
    void Update();
    bool CanStart();
    bool CanPause();
    bool CanSplit();
    bool CanReset();
    bool CanGoToNextSegment();
    bool CanGoToPreviousSegment();
    bool CloseSplitsToTimer();
    
    bool SetOneDecimal();
    bool SetTwoDecimal();
    bool SetThreeDecimal();
    bool SetNoDecimal();
    
    bool ShowRunTitle();
    bool ShowRunAttempts();
    bool NoRunTitle();
    bool NoRunAttempts();
    bool ShowBothTitleAttempts();
    bool HideBothTitleAttempts();
    
    int ShowTitle;
    int ShowAttempts;
    
    int splitprotection;
    
    bool splitsLoaded;
    bool ReturnSplitsLoaded();
    int ReturnSplit(int i);
    int ReturnSplitIndex();
    int ReturnCurrentTime();
    bool ReturnRunFinished();
    bool RunFinished;
    
    std::string AddSplitNameToArray(std::string name);
    std::string AddSplitTimeToArray(int time);
    std::string split_names;
    std::string split_times;
    std::string ReturnSplitNames();
    std::string ReturnSplitTimes();
    
    void Edit();
    int firstsplit;
    int millis_remaining;
    int millisToShow;
    std::string DisplayMilliseconds(unsigned long milliseconds, bool includeMilliseconds);
    std::string homedir;
    
    std::string ReturnTitle();
    int ReturnAttempts();
    void UpdateEdittedSplits(std::string title, int attempts, int split_count, std::string split_names, std::string split_times);
private:
    void ReloadSplits();
    void UpdateSplits();
    std::shared_ptr<WebBrowserInterface> _browser;
    std::vector<std::shared_ptr<Split> > _splits;
    int _currentSplitIndex;
    std::string _settings_file;
    std::shared_ptr<Timer> _timer;
    std::string _title;
    int _attempts;
    std::string run_attempts;
};

#endif /* defined(__SplitsCore__CoreApplication__) */
