#ifndef _SS_STATE_
#define _SS_STATE_

#include <sstream>
#include "common.h"

using namespace std;

typedef struct {
    char* value;
    bool typePattern;
    bool typeCase;
} CaseStat;

class SwitchStatementState
{
    public:
        bool initialized;    
        bool dandlingDefault;
        std::stack<CaseStat> sstack;
        SwitchStatementState()
        {
            dandlingDefault=0x0;
            initialized=false;
        }
        char* getCompleteText(char* statements)
        {
            stringstream ss;
            int num = this->sstack.size();
            if (num>0)
            {
                if (this->initialized) {
                   ss << "else";
                } else {
                   this->initialized=true;
                }
                ss<<"if ";
                bool c_s_first=true;
                stringstream condStream;
                while(!this->sstack.empty())
                {
                    if(!c_s_first)
                    {
                        condStream << " or ";
                    } else 
                    {
                        c_s_first=false;
                    }
                    if (this->sstack.top().typeCase)
                    {
                        condStream<<"( switch_var == "<<this->sstack.top().value<<")";
                    } else if (this->sstack.top().typePattern)                
                    {
                        condStream<<"( string.match(switch_var,\""<<this->sstack.top().value<<"\") ~= nil )";
                    }
                    this->sstack.pop();
                }
                if (num>1)
                {
                    ss <<"("<< condStream.str()<<")";
                } else {
                    ss << condStream.str();
                }
                ss<<" then"<<endl<<statements;
            }
            if (dandlingDefault)
            {
                ss<<"else "<<endl<<statements;
            }
            return alloc_string((char*)ss.str().data());
        }
};

#endif
