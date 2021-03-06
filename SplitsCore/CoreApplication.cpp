//
//  CoreApplication.cpp
//  SplitsCore
//
//  Created by Edward Waller on 10/17/12.
//  Copyright (c) 2012 Edward Waller. All rights reserved.
//
// taken over by DJS around 1 nov 2013

#include "CoreApplication.h"
#include <sstream>
#include <fstream>
#include <vector>
#include <iomanip>
#include <SplitsCore/Split.h>
#include <yaml.h>
#include <stdio.h>
#include <stdlib.h>


bool StartsWith(std::string input, std::string prefix) {
    return !input.compare(0, prefix.size(), prefix);
}

std::vector<std::string> SplitString(const std::string &s, char delim) {
    std::vector<std::string> elems;
    std::stringstream ss(s);
    std::string item;
    while(std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

CoreApplication::CoreApplication(std::shared_ptr<WebBrowserInterface> browser, std::string settings_file) : _browser(browser), _settings_file(settings_file), _currentSplitIndex(0), _timer(new Timer), _attempts(0), _title("") {
    _browser->LoadHTML(); // the html is now loaded from 'html/splits.html'
    firstsplit=1; // this is for start/split same key (DJS)
    splitprotection=0;
}

std::shared_ptr<Timer> CoreApplication::timer() {
    return _timer;
}

void CoreApplication::LoadSplits(std::string file) {
    _splits.clear();
    
    std::ifstream file_stream(file);
    YAML::Parser parser(file_stream);
    YAML::Node doc;
    parser.GetNextDocument(doc);
    doc["title"] >> _title; // title is retrieved here (DJS)
    doc["attempts"] >> _attempts;
    printf("LoadSplits: read %i attempts\n", _attempts);
    
    const YAML::Node& splits = doc["splits"];
    
    for(unsigned i = 0; i < splits.size(); i++) {
        std::shared_ptr<Split> split(new Split);
        std::string name;
        splits[i]["name"] >> name;
        split->set_name(name);
        unsigned long milliseconds;
        splits[i]["time"] >> milliseconds;
        split->set_time(milliseconds);
        AddSplitNameToArray(name);
        AddSplitTimeToArray(milliseconds);
        _splits.push_back(split);
    }
    
    file_stream.close();
    splitsLoaded = true;
    ReloadSplits();
}

void CoreApplication::SaveSplits(std::string file) {
    std::ofstream file_stream;
    file_stream.open(file);
    
    YAML::Emitter out;
    out << YAML::BeginMap;
    out << YAML::Key << "title";
    out << YAML::Value << _title;
    out << YAML::Key << "attempts";
    out << YAML::Value << _attempts;
    out << YAML::Key << "splits";
    out << YAML::Value;
    out << YAML::BeginSeq;
    
    for(int i = 0; i < _splits.size(); i++) {
        out << YAML::BeginMap;
        out << YAML::Key << "name";
        out << YAML::Value << _splits[i]->name();
        out << YAML::Key << "time";
        std::shared_ptr<Split> lastSplit = _splits[_splits.size() - 1];
        
        out << YAML::Value;
        if(lastSplit->time() > lastSplit->new_time() && lastSplit->new_time() != 0) {
            out << _splits[i]->new_time();
        } else {
            out << _splits[i]->time();
        }
        out << YAML::EndMap;
    }
    
    out << YAML::EndSeq;
    out << YAML::EndMap;

    file_stream << out.c_str();
    file_stream.close();
    
}

void CoreApplication::LoadWSplitSplits(std::string file) {
    _splits.clear();
    
    std::string line = "";
    std::ifstream file_stream;
    std::string title_equals = "Title=";
    std::string goal_equals = "Goal=";
    std::string attempts_equals = "Attempts=";
    std::string size_equals = "Size=";
    std::string offset_equals = "Offset=";
    std::string icons_equals = "Icons=";
    
    file_stream.open(file);
    
    int i = 0;
    while (!file_stream.eof())
    {
        getline(file_stream, line);
        
        // Remove \r from end of line.
        //line = line.substr(0, line.size() - 1);
        
        // Skip empty lines.
        if(line.size() > 0) {
            if(StartsWith(line, title_equals)) {
                _title = line.substr(title_equals.size(), line.size() - title_equals.size());
            } else if(StartsWith(line, attempts_equals)) {
                std::string attempts = line.substr(attempts_equals.size(), line.size() - attempts_equals.size());
                _attempts = atoi(attempts.c_str());
            } else if(StartsWith(line, size_equals)) {
                std::string size = line.substr(size_equals.size(), line.size() - size_equals.size());
            } else if(StartsWith(line, goal_equals)) {
                std::string size = line.substr(size_equals.size(), line.size() - size_equals.size());
            } else if(StartsWith(line, offset_equals)) {
                std::string offset = line.substr(offset_equals.size(), line.size() - offset_equals.size());
            } else if(StartsWith(line, icons_equals)) {
                
            } else {
                // Split
                std::vector<std::string> split_values = SplitString(line, ',');
                
                std::shared_ptr<Split> split(new Split);
                split->set_name(split_values[0]);
                double split_seconds = atof(split_values[2].c_str());
                unsigned long milliseconds = split_seconds * 1000;
                split->set_time(milliseconds);
                AddSplitNameToArray(split_values[0]);
                AddSplitTimeToArray(milliseconds);
                _splits.push_back(split); // problematic line
            }
        }
        
        i++;
    }
    
    file_stream.close();
    splitsLoaded = true;
    ReloadSplits();
}

void CoreApplication::SaveWSplitSplits(std::string file) {
    std::ofstream file_stream;
    file_stream.open(file);
    file_stream << "Title=" << _title << "\n";
    file_stream << "Attempts=" << _attempts << "\n";
    for(int i = 0; i < _splits.size(); i++) {
        std::shared_ptr<Split> lastSplit = _splits[_splits.size() - 1];
        unsigned long ms = _splits[i]->time();
        float secs = ms / 1000.0;
        file_stream << _splits[i]->name() << ",0," << secs << ",0\n";
    }
    file_stream.close();
}



void CoreApplication::StartTimer() {
    _timer->Start();
    RunFinished = false;
    firstsplit=0;
}

void CoreApplication::StopTimer() {
    _timer->Stop();
}

void CoreApplication::ResetTimer() {
    firstsplit=1; // this is for start/split being the same hotkey (DJS)
    _currentSplitIndex = 0;
    RunFinished = false;
    if(_timer->status() == kRunning) { // If timer was runnning, increment attempts
        _attempts++;
    }
    _timer->Reset();
    //UpdateSplits();
    ReloadSplits();
}

void CoreApplication::SplitTimer() {
    if (firstsplit==1) { // this is for start/split being the same hotkey (DJS)
        firstsplit=0;
        _timer->Start();
    } else {
        if (time(NULL)>splitprotection) {
            splitprotection=time(NULL)+2; // 2 second split protection (DJS)
            if(_splits.size() == 0) {
                StopTimer();
                UpdateSplits();
            }
            if(_currentSplitIndex < _splits.size()) {
                _splits[_currentSplitIndex]->set_new_time(_timer->GetTimeElapsedMilliseconds());
                _currentSplitIndex++;
                if(_currentSplitIndex == _splits.size()) {
                    StopTimer();
                    // Run finished here
                    RunFinished = true;
                    
                }
                UpdateSplits();
            } else {
                // split protection - do nothing (DJS)
            }
        }
    }
}

int CoreApplication::ReturnSplit(int i) {
    i = i - 1;
    if (i < _splits.size()) {
        unsigned long elapsed = _timer->GetTimeElapsedMilliseconds();
        unsigned long total = elapsed - _splits[i]->time();
        //printf("duration for %i: %i%\n", i, total);
        return total;
    } else {
        return 0;
    }
}

int CoreApplication::ReturnSplitIndex() {
    return _currentSplitIndex;
}

int CoreApplication::ReturnCurrentTime() {
    return _timer->GetTimeElapsedMilliseconds();
}

bool CoreApplication::ReturnRunFinished() {
    printf("RunFinished: %d \n", RunFinished);
    return RunFinished;
}

void CoreApplication::PauseTimer() {
    
}

void CoreApplication::ResumeTimer() {
    
}

void CoreApplication::GoToNextSegment() {
    if(CanGoToNextSegment()) {
        _splits[_currentSplitIndex]->set_skipped(true);
        _currentSplitIndex++;
        UpdateSplits();
    }
}

void CoreApplication::GoToPreviousSegment() {
    if(CanGoToPreviousSegment()) {
        _currentSplitIndex--;
        _splits[_currentSplitIndex]->set_skipped(false);
        UpdateSplits();
        if(_timer->status() == kFinished) {
            // Start the timer again if they go to the previous segment after finishing.
            _timer->Resume();
        }
    }
}

void CoreApplication::ChangeSetting(std::string key, std::string value) {
    
}

std::string CoreApplication::DisplayMilliseconds(unsigned long milliseconds, bool includeMilliseconds) {
    int hours = milliseconds / (1000*60*60);
    int mins = (milliseconds % (1000*60*60)) / (1000*60);
    int seconds = ((milliseconds % (1000*60*60)) % (1000*60)) / 1000;
    
    if (millisToShow==3) {
        millis_remaining = ((milliseconds % (1000*60*60)) % (1000*60)) % 1000; // 3 decimals
    }
    
    if (millisToShow==2) {
        millis_remaining = ((milliseconds % (1000*60*60)) % (1000*60)) % 1000 / 10; // 2 decimals
    }
    
    if (millisToShow==1) {
        millis_remaining = ((milliseconds % (1000*60*60)) % (1000*60)) % 1000 / 100; // 1 decimal
    }
    
    if (millisToShow==NULL) { // default
        millis_remaining = ((milliseconds % (1000*60*60)) % (1000*60)) % 1000 / 100; // 1 decimal
        millisToShow=1;
    }
    
    std::stringstream ss;
    ss << std::setfill('0');
    if(hours > 0) {
        ss << "<span class=\"hours\">" << hours << "</span><span class=\"separator\">:</span>";
    }
    if(hours == 0 && mins > 0) {
        ss << "<span class=\"minutes\">" << mins << "</span><span class=\"separator\">:</span>";
    } else if(hours > 0) {
        ss << "<span class=\"minutes\">" << std::setw(2) << mins << "</span><span class=\"separator\">:</span>";
    }
    if(hours == 0 && mins == 0) {
        ss << "<span class=\"seconds\">" << seconds << "</span>";
    } else {
        ss << "<span class=\"seconds\">" << std::setw(2) << seconds << "</span>";;
    }
    if(millisToShow>0) {
        ss << "<span class=\"decimal\">,</span>" << "<span class=\"milliseconds\">" << std::setw(millisToShow) << millis_remaining << "</span>";
    }else if (millisToShow<0) {
        ss << "";
    }
    
    return ss.str();
}

void CoreApplication::Update() {
    unsigned long elapsed = _timer->GetTimeElapsedMilliseconds();
    std::stringstream javascript_ss;
    javascript_ss << "$('#timer').html('" << DisplayMilliseconds(elapsed, true) << "');";
    
    if(_currentSplitIndex < _splits.size()) {
        if(_splits[_currentSplitIndex]->time() < elapsed) {
            unsigned long total = elapsed - _splits[_currentSplitIndex]->time();
            javascript_ss << "$('.current_split .split_time').html('+" << DisplayMilliseconds(total, false) << "').addClass('plus');";
        }
    }
    
    _browser->RunJavascript(javascript_ss.str());
}

void CoreApplication::ReloadSplits() {
    
    std::stringstream javascript_ss;
    
    if (splitsLoaded == false) {
        ShowTitle = 0;
        ShowAttempts = 0;
        _splits.clear();
        javascript_ss << "document.getElementById('splits').innerHTML = '';";
    } else if (splitsLoaded == true) {
        run_attempts = std::to_string(_attempts); // convert integer to string (DJS)
        
        std::string html = "";
        for(int i = 0; i < _splits.size(); i++) {
            html += "<tr><td class=\"split_name\">";
            html += _splits[i]->name();
            html += "</td><td class=\"split_time\">";
            html += DisplayMilliseconds(_splits[i]->time(), false);
            html += "</td></tr>";
        }
        
        javascript_ss << "document.getElementById('splits').innerHTML = '";
        javascript_ss << html;
        javascript_ss << "';";
    }
    
    _browser->RunJavascript(javascript_ss.str());
    //_currentSplitIndex = 0;
    UpdateSplits();
}

void CoreApplication::UpdateEdittedSplits(std::string title, int attempts, int split_count, std::string split_names, std::string split_times) {
    _splits.clear();
    printf("c++ Timer Core got Update Splits request. \n# of splits: %i \n", split_count);
    _title = title;
    _attempts = attempts;
    
    // Split crocodile strings into arrays here
    std::cout << "c++ Timer Core got these names back:" << split_names << "\n";
    std::cout << "c++ Timer Core got these times back:" << split_times << "\n";
    
    std::replace(split_times.begin(), split_times.end(), '@', ' ');
    
    if (split_times.find("<null>") == std::string::npos) { // Check if any times are null, as that will cause problems otherwise
        // Names to array called names_array
        std::vector<std::string> names_array;
        std::stringstream ss(split_names);
        std::string tmp;
        while(std::getline(ss, tmp, '@')){ // Split split names by @
            names_array.push_back(tmp);
        }
        for(auto it = names_array.begin(); it != names_array.end(); ++it) {
            std::cout << (*it) << std:: endl;
        }
        
        // Times to vector v, from https://stackoverflow.com/a/23697112
        std::stringstream sss(split_times);
        std::vector<int> v;
        std::copy( std::istream_iterator<int>( sss), std::istream_iterator<int>(),
                  std::back_inserter(v));
        
        // To splits
        for(unsigned i = 0; i < split_count; i++) {
            std::shared_ptr<Split> split(new Split);
            split->set_name(names_array[i]);
            split->set_time(v[i]);
            //AddSplitNameToArray(names_array[i]);
            //AddSplitTimeToArray(milliseconds);
            _splits.push_back(split);
        }
        splitsLoaded = true;
        ReloadSplits();
    }
}

void CoreApplication::UpdateSplits() {
    // Update current split class.
    std::stringstream javascript_ss;
    
    // Title and Attempt Display
    if (ShowAttempts==1 && ShowTitle==1) { // show both
        run_attempts = std::to_string(_attempts);
        javascript_ss << "$('#runtitle').html('" << _title << " - #" << run_attempts << "');";
    } else if (ShowAttempts==1 && ShowTitle==0) { // show attempts
        run_attempts = std::to_string(_attempts);
        javascript_ss << "$('#runtitle').html('#" << run_attempts << "');";
    } else if (ShowTitle==1 && ShowAttempts==0) {
        javascript_ss << "$('#runtitle').html('" << _title << "');";
    } else if (ShowTitle==0 && ShowAttempts==0) { // none
        javascript_ss << "$('#runtitle').html('');";
    }
    
    javascript_ss << "$('#splits tr').removeClass('current_split').eq(" << _currentSplitIndex << ").addClass('current_split');";
    for(int i = 0; i < _currentSplitIndex; i++) {
        unsigned long old_time = _splits[i]->time();
        unsigned long new_time = _splits[i]->new_time();
        if(_splits[i]->skipped()) {
            javascript_ss << "$('#splits td.split_time:eq(" << i << ")').removeClass('minus').removeClass('plus').html('-');";
        } else if(old_time > new_time) {
            // Negative
            unsigned long total = old_time - new_time;
            javascript_ss << "$('#splits td.split_time:eq(" << i << ")').html('-" << DisplayMilliseconds(total, false) << "');";
            javascript_ss << "$('#splits td.split_time:eq(" << i << ")').addClass('minus');";
        } else {
            unsigned long total = new_time - old_time;
            javascript_ss << "$('#splits td.split_time:eq(" << i << ")').html('+" << DisplayMilliseconds(total, false) << "');";
            javascript_ss << "$('#splits td.split_time:eq(" << i << ")').addClass('plus');";
        }
    }
    for(int i = _currentSplitIndex; i < _splits.size(); i++) {
        javascript_ss << "$('#splits td.split_time:eq(" << i << ")').removeClass('minus').removeClass('plus').html('" << DisplayMilliseconds(_splits[i]->time(), false) << "');";
    }
    _browser->RunJavascript(javascript_ss.str());
}

bool CoreApplication::CanStart() {
    return _timer->status() != kRunning && _timer->status() != kFinished;
}

bool CoreApplication::CanPause() {
    return _timer->status() == kRunning;
}

bool CoreApplication::CanSplit() {
    return _timer->status() == kRunning;
}

bool CoreApplication::CanReset() {
    return _timer->status() != kInitial;
}

bool CoreApplication::CanGoToNextSegment() {
    return _timer->status() != kFinished && _currentSplitIndex + 1 < _splits.size();
}

bool CoreApplication::CanGoToPreviousSegment() {
    return _currentSplitIndex > 0;
}

bool CoreApplication::SetOneDecimal() {
    millisToShow=1;
    UpdateSplits();
    return 0;
}

bool CoreApplication::SetTwoDecimal() {
    millisToShow=2;
    UpdateSplits();
    return 0;
}

bool CoreApplication::SetThreeDecimal() {
    millisToShow=3;
    UpdateSplits();
    return 0;
}

bool CoreApplication::CloseSplitsToTimer() {
    printf("Core: Got close request");
    // Close and open just timer
    split_names = "";
    split_times = "";
    _currentSplitIndex=0;
    _attempts=0;
    _title = "";
    _splits.clear();
    firstsplit=1;
    splitprotection=0;
    splitsLoaded = false;
    _timer->Reset();
    ReloadSplits();
    return 0;
}

bool CoreApplication::SetNoDecimal() {
    millisToShow=-1;
    UpdateSplits();
    return 0;
}


// Titles and attempts display
bool CoreApplication::ShowRunTitle() {
    ShowTitle=1;
    UpdateSplits();
    //ResetTimer();
    return 0;
}

bool CoreApplication::ShowRunAttempts() {
    ShowAttempts=1;
    UpdateSplits();
    return 0;
}

bool CoreApplication::NoRunTitle() {
    ShowTitle=0; // yes i know i can use bool's instead of int's. but this works so who cares (DJS)
    // i was an idiot in 2013-2014 /DJS 2017
    //ResetTimer();
    UpdateSplits();
    return 0;
}

bool CoreApplication::NoRunAttempts() {
    ShowAttempts=0;
    //ResetTimer();
    UpdateSplits();
    return 0;
}

bool CoreApplication::ShowBothTitleAttempts() {
    ShowAttempts=1;
    ShowTitle=1;
    UpdateSplits();
    return 0;
}

bool CoreApplication::HideBothTitleAttempts() {
    ShowAttempts=0;
    ShowTitle=0;
    UpdateSplits();
    return 0;
}

std::string CoreApplication::ReturnTitle() {
    std::stringstream title;
    title << _title;
    return title.str();
}

int CoreApplication::ReturnAttempts() {
    int attempts;
    attempts = _attempts;
    return _attempts;
}

bool CoreApplication::ReturnSplitsLoaded() {
    return splitsLoaded;
}

std::string CoreApplication::AddSplitNameToArray(std::string name) {
    split_names += name;
    split_names += "@";
    printf("AddSplitNameToArray: %s\n", split_names.c_str());
}

std::string CoreApplication::AddSplitTimeToArray(int time) {
    split_times += std::to_string(time);
    split_times += "@";
    printf("AddSplitTimeToArray: %s\n", split_times.c_str());
}

std::string CoreApplication::ReturnSplitNames() {
    return split_names;
}

std::string CoreApplication::ReturnSplitTimes() {
    return split_times;
}

void CoreApplication::Edit() {
    _browser->RunJavascript("$('#splits').removeClass('active').addClass('editing');$('#splits tr').append('<td class=\"remove_split\">-</td><td class=\"add_split\">+</td>');$('#splits').append('<tr><td></td><td></td><td></td><td class=\"add_split\">+</td>');$('.split_name, .split_time').attr('contentEditable', true);$('.split_name').first().focus();");
}
