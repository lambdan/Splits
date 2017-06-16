//
//  timer.h
//  SplitsCore
//
//  Created by Edward Waller on 10/15/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#ifndef __SplitsCore__timer__
#define __SplitsCore__timer__

#include <iostream>

enum TimerStatus {
    kInitial,
    kRunning,
    kFinished,
    kPaused
};

class Timer {
public:
    Timer();
    ~Timer();
    void Start();
    void Stop();
    void Pause();
    void Resume();
    void Reset();
    std::chrono::high_resolution_clock::duration GetTimeElapsed();
    unsigned long GetTimeElapsedMilliseconds();
    TimerStatus status();
private:
    std::chrono::time_point<std::chrono::high_resolution_clock> _start_time;
    TimerStatus _status;
    std::chrono::high_resolution_clock::duration _stopTime;
};

#endif /* defined(__SplitsCore__timer__) */
