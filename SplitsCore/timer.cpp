//
//  timer.cpp
//  SplitsCore
//
//  Created by Edward Waller on 10/15/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//

#include "timer.h"
#include <sstream>
#include <iomanip>

Timer::Timer() : _status(kInitial) {
    
}

Timer::~Timer() {
    
}

TimerStatus Timer::status() {
    return _status;
}

void Timer::Start() {
    _status = kRunning;
    _start_time = std::chrono::high_resolution_clock::now();
}

void Timer::Stop() {
    _stopTime = GetTimeElapsed();
    _status = kFinished;
}

void Timer::Pause() {
    
}

void Timer::Resume() {
    if(_status == kFinished) {
        _status = kRunning;
    }
}

void Timer::Reset() {
    _status = kInitial;
}

std::chrono::high_resolution_clock::duration Timer::GetTimeElapsed() {
    if(_status == kRunning) {
        return std::chrono::high_resolution_clock::now() - _start_time;
    } else if(_status == kFinished) {
        return _stopTime;
    } else {
        return std::chrono::high_resolution_clock::duration(0);
    }

}

unsigned long Timer::GetTimeElapsedMilliseconds() {
    std::chrono::high_resolution_clock::duration duration = GetTimeElapsed();
    std::chrono::milliseconds mils = std::chrono::duration_cast<std::chrono::milliseconds>(duration);
    return mils.count();
}