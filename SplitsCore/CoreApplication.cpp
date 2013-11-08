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
    _browser->LoadHTML("<html>\
                       <head>\
                       <script src=\"http://ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js\"></script>\
                       <style type=\"text/css\" media=\"screen\">\
                       body {\
                           font-family: \"Helvetica Neue\",Helvetica,Arial,sans-serif;\
                           font-size: 1em;\
                           color: #CCC;\
                           background-color: #000;\
                           margin: 0;\
                       }\
                       #timer {\
                           text-align: right;\
                           font-size: 2em;\
                           color: #C679FF;\
                           font-weight: bold;\
                           margin-right: 5px;\
                       }\
                       #splits_container {\
                           overflow: auto;\
                       }\
                       #splits_container::-webkit-scrollbar {\
                           display: none;\
                       }\
                       #splits {\
                           outline: 0px solid transparent;\
                           width: 100%;\
                           border-spacing: 0;\
                       }\
                       #splits td {\
                           margin: 0;\
                           border-bottom: 1px solid #000;\
                           border-top: 1px solid #000;\
                       }\
                       .add_split, .remove_split {\
                           text-align: center;\
                           min-width: 20px;\
                           width: 20px;\
                           font-weight: bold;\
                           cursor: pointer;\
                       }\
                       .remove_split {\
                           color: red;\
                       }\
                       .add_split {\
                           color: #00FF00;\
                       }\
                       .split_name {\
                           padding-left: 5px;\
                       }\
                       .split_time {\
                           text-align: right;\
                           padding-right: 5px;\
                       }\
                       .split_time.minus {\
                           color: #00BFFF;\
                       }\
                       .split_time.plus {\
                           color: #FF4000;\
                       }\
                       #splits.active .current_split td {\
                           border-bottom: 1px solid #1165B5;\
                           border-top: 1px solid #1165B5;\
                           color: #FFF;\
                       }\
                       #splits.editing {\
                           color: #FFF;\
                       }\
                       .milliseconds {\
                           margin-left: 5px;\
                           font-size: 0.65em;\
                       }\
                       .decimal {\
                           display: none;\
                       }\
                       </style>\
                       </head>\
                        <body>\
                           <div id=\"splits_container\">\
                           <table id=\"splits\" class=\"active\"></table>\
                           </div>\
                           <div id=\"timer\"></div>\
                        </body>\
                        </html>"
                       );
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
    doc["title"] >> _title; // title is retrieved here? (DJS)
    doc["attempts"] >> _attempts;
    
    const YAML::Node& splits = doc["splits"];
    
    for(unsigned i = 0; i < splits.size(); i++) {
        std::shared_ptr<Split> split(new Split);
        std::string name;
        splits[i]["name"] >> name;
        split->set_name(name);
        unsigned long milliseconds;
        splits[i]["time"] >> milliseconds;
        split->set_time(milliseconds);
        _splits.push_back(split);
    }
    
    file_stream.close();
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
        line = line.substr(0, line.size() - 1);

        // Skip empty lines.
        if(line.size() > 0) {
            if(StartsWith(line, title_equals)) {
                _title = line.substr(title_equals.size(), line.size() - title_equals.size());
            } else if(StartsWith(line, attempts_equals)) {
                std::string attempts = line.substr(attempts_equals.size(), line.size() - attempts_equals.size());
                _attempts = atoi(attempts.c_str());
            } else if(StartsWith(line, size_equals)) {
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
                _splits.push_back(split);
            }
        }
        
        i++;
    }
    
    file_stream.close();
    ReloadSplits();
}

void CoreApplication::SaveWSplitSplits(std::string file) {
    
}

void CoreApplication::StartTimer() {
    _timer->Start();
    firstsplit=0;
}

void CoreApplication::StopTimer() {
    _timer->Stop();
}

void CoreApplication::ResetTimer() {
    _timer->Reset();
    firstsplit=1; // this is for start/split being the same hotkey
    _currentSplitIndex = 0;
    _attempts++;
    UpdateSplits();
}

void CoreApplication::SplitTimer() {
    if (firstsplit==1) { // this is for start/split being the same hotkey
        firstsplit=0;
        _timer->Start();
    } else {
        // insert double hit split-key protection here
        if (time(NULL)>splitprotection) {
            splitprotection=time(NULL)+2; // 2 second split protection
            if(_splits.size() == 0) {
                StopTimer();
                UpdateSplits();
            }
            if(_currentSplitIndex < _splits.size()) {
                    _splits[_currentSplitIndex]->set_new_time(_timer->GetTimeElapsedMilliseconds());
                    _currentSplitIndex++;
            if(_currentSplitIndex == _splits.size()) {
                StopTimer();
            }
                UpdateSplits();
        } else {
        // split protection - do nothing
        }
        }
    }
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
        millis_remaining = ((milliseconds % (1000*60*60)) % (1000*60)) % 1000 / 10; // 2 decimals
        millisToShow=2;
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
        ss << "<span class=\"decimal\">.</span>" << "<span class=\"milliseconds\">" << std::setw(millisToShow) << millis_remaining << "</span>";
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
    
    _browser->RunJavascript(javascript_ss.str());
    
    _currentSplitIndex = 0;
    UpdateSplits();
}

void CoreApplication::UpdateSplits() {
    // Update current split class.
    std::stringstream javascript_ss;
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
}
bool CoreApplication::SetTwoDecimal() {
    millisToShow=2;
    UpdateSplits();
}

bool CoreApplication::SetThreeDecimal() {
    millisToShow=3;
    UpdateSplits();
}

bool CoreApplication::SetNoDecimal() {
    millisToShow=-1;
    UpdateSplits();
}

void CoreApplication::Edit() {
    _browser->RunJavascript("$('#splits').removeClass('active').addClass('editing');$('#splits tr').append('<td class=\"remove_split\">-</td><td class=\"add_split\">+</td>');$('#splits').append('<tr><td></td><td></td><td></td><td class=\"add_split\">+</td>');$('.split_name, .split_time').attr('contentEditable', true);$('.split_name').first().focus();");
}