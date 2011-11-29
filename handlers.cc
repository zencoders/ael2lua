#include <sstream>
#include <vector>
#include <string>
#include <string.h>
#include "handlers.h"
#include "utilities.h"

using namespace std;

bool luaExtAllocated=false;
bool luaHintsAllocated=false;
std::vector<std::string> hints;

string time2iftime(TimeStruct* ts)
{
    stringstream ss;
    ss << "temp = os.date()" << endl;
    ss << "if (";
    bool first = true;
    if(ts->beginMonth != "")
    {
        ss << "temp.month >= " << ts->beginMonth << ((ts->endMonth != "") ? (" and temp.month < " + string(ts->endMonth)) : "");
        first = false;
    }
    if(ts->beginDOM != "")
    {
        if(!first)
            ss << " and ";
        ss << "temp.day >= " << ts->beginDOM << ((ts->endDOM != "") ? (" and temp.day < " + string(ts->endDOM)) : "");
        first = false;
    }
    if(ts->beginDay != "")
    {
        if(!first)
            ss << " and ";
        ss << "temp.wday >= " << ts->beginDay << ((ts->beginDay != "") ? (" and temp.wday < " + string(ts->endDay)) : "");
        first = false;
    }
    if(!first)
        ss << " and ";
    ss << "(temp.hour + 0.01 * temp.min) >= " << ts->beginHour << "." << ts->beginMinutes;
    ss << " and (temp.hour + 0.01 * temp.min) < " << ts->endHour << "." << ts->endMinutes;
    ss << ") then" << endl;
    return ss.str();
}

void handleTimes(char* t1, char* t2, char* t3, char* day, char* md, char* m, TimeStruct* ts)
{
    string bh(t1);
    string em(t3);
    vector<string> second_word = split(t2, '-');
    ts->beginHour = alloc_string((char*)trim(bh).data());
    ts->beginMinutes = alloc_string((char*)trim(second_word[0]).data());
    ts->endHour = alloc_string((char*)trim(second_word[1]).data());
    ts->endMinutes = alloc_string((char*)trim(em).data());
    string dw(day);
    string dayword(trim(dw));
    string beginDayString = "";
    string endDayString = "";
    if(dayword != "*")
    {
        vector<string> days = split(dayword, '-');
        beginDayString = sday2iday(trim(days[0]));
        if(days.size() > 1)
        {
            endDayString = sday2iday(trim(days[1]));
        }
    }
    ts->beginDay = alloc_string((char*)beginDayString.data());
    ts->endDay = alloc_string((char*)endDayString.data());
    string dom(md);
    string dayOfMonth(trim(dom));
    string beginDOMString = "";
    string endDOMString = "";
    if(dayOfMonth != "*")
    {
        vector<string> monthDays = split(dayOfMonth, '-');
        beginDOMString = trim(monthDays[0]);
        if(monthDays.size() > 1)
        {
            endDOMString = trim(monthDays[1]);
        }
    }
    ts->beginDOM = alloc_string((char*)beginDOMString.data());
    ts->endDOM = alloc_string((char*)endDOMString.data());
    string mon(m);
    string month(trim(mon));
    string beginMonthString = "";
    string endMonthString = "";
    if(month != "*")
    {
        vector<string> months = split(month, '-');
        beginMonthString = smonth2imonth(trim(months[0]));
        if(months.size() > 1)
        {
            endMonthString = smonth2imonth(trim(months[1]));
        }
    }
    ts->beginMonth = alloc_string((char*)beginMonthString.data());
    ts->endMonth = alloc_string((char*)endMonthString.data());
}

void handleTimes(char* time, char* day, char* md, char* m, TimeStruct* ts)
{
    char* t1;
    char* t2;
    char* t3;
    if(string(time) == "*")
    {
        t1 = (char*)"00";
        t2 = (char*)"00-23";
        t3 = (char*)"59";
    }
    else
    {
        vector<string> time_parts = split(time, ':');
        t1 = (char*) time_parts[0].data();
        t2 = (char*) time_parts[1].data();
        t3 = (char*) time_parts[2].data();
    }
    handleTimes(t1,t2,t3,day,md,m,ts);
}

char* handleIf(char* head, char* statement)
{
    stringstream ss;
    ss << head << statement << endl << "end";
    return alloc_string((char*)ss.str().data());
}

char* handleIfElse(char* head, char* statement, char* statement2)
{
    stringstream ss;
    ss << head << statement << endl << "else" << endl << statement2 << endl << "end";
    return alloc_string((char*)ss.str().data());
}

char* handleIncludedName(char* name)
{
    stringstream ss;
    ss << "\"" << name << "\"";
    return alloc_string((char*)ss.str().data());
}

char* handleMacroDef(char* name,char* arglist, char* stats)
{
    stringstream ss;
    ss<<"function "<<name<<"("<<arglist<<")"<<endl;
    ss<<stats;
    ss<<"end"<<endl<<endl;
    return alloc_string((char*)ss.str().data());
}

char* handleContext(char* name,char* content)
{
    stringstream ss; 
    if (!luaExtAllocated)
    {
        luaExtAllocated = true;
        ss << "extensions = {}"<<endl;
    }
    if(!luaHintsAllocated && hints.size())
    {
        luaHintsAllocated = true;
        ss << "hints = {}" << endl;
    }
    ss << "extensions." << name << " = "<<endl<<"{"<<endl;
    if (strlen(content)>0)
    {
        ss<<content<<endl;
    }
    ss<<"}" << endl<<endl;
    if(hints.size())
    {
        ss << "hints." << name << " = "<<endl<<"{"<<endl;
        for(int i = 0; i < hints.size(); i++)
        {
            ss << hints[i] << endl;
        }
        ss << "}" << endl << endl;
    }
    hints.clear();
    return alloc_string((char*)ss.str().data());
}

void store_hint(char* h)
{
    hints.push_back(h);
}
