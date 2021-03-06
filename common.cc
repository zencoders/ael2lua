#include <stdlib.h>
#include <stdio.h>
#include <stddef.h>
#include <set>
#include <cstring>
#include <string>
#include <sstream>
#include "utilities.h"

std::set<char*> garbage;

char* calloc_string(char* d)
{
    char* s = (char*) calloc((strlen(d) + 1),sizeof(char));
    strcpy(s, d);
    return s;
}

void destroy_string(char* p)
{
    std::set<char*>::iterator it = garbage.find(p);
    if(it != garbage.end())
    {
        free(*it);
        garbage.erase(it);
    }
}

void recycle_garbage()
{
    std::set<char*>::iterator it;
    for(it = garbage.begin(); it != garbage.end(); it++)
    {
        free(*it);
    }
    garbage.clear();
}

char* alloc_string(char* d)
{
    char* s = calloc_string(d);
    garbage.insert(s);
    return s;
}

char* grow_string(char* head, char* tail)
{
    char* s = (char*) calloc((strlen(head) + strlen(tail) + 2), sizeof(char));
    sprintf(s,"%s%s", head, tail);
    destroy_string(head); //IT IS SUPPOSED head ALLOCATED USING MALLOC
    garbage.insert(s);
    return s;
}

char* extract_variable(char* s)
{
    std::string var(s);
    char* to_ret;
    if(var.size() >= 3)
    {
        if(s[0] == '$' && s[1] == '{')
        {
            size_t colon_pos = var.find(':');
            if(colon_pos != std::string::npos)
            {
                std::string head = var.substr(2, colon_pos - 2);
                std::string tail = var.substr(colon_pos + 1, var.size() - 2 - colon_pos);
                tail = extract_variable((char*)tail.data());
                std::stringstream ss;
                ss << head << "[" << tail << "]";
                to_ret = alloc_string((char*)ss.str().data());
            }
            else
            {
                to_ret = alloc_string((char*)var.substr(2,var.size()-3).data());
            }
        }
        else
        {
            std::stringstream ss;
            if(!isNumeric(s,10))
                ss << "\"" << s << "\"";
            else
                ss << s;
            to_ret = alloc_string((char*)ss.str().data());
        }
    }
    else
    {
        std::stringstream ss;
        if(!isNumeric(s,10))
            ss << "\"" << s << "\"";
        else
            ss << s;
        to_ret = alloc_string((char*)ss.str().data());
    }
    return to_ret;
}

char* extract_binary_expr(char* a, char* b, char* c)
{
    std::stringstream ss;
    ss << a << " " << b << " " << c;
    return alloc_string((char*)ss.str().data());
}

char* extract_unary_expr(char* a, char* b)
{
    std::stringstream ss;
    ss << a << b;
    return alloc_string((char*) ss.str().data());
}

char* extract_conditional_op(char* a, char* b, char* c)
{
    std::stringstream ss;
    ss << "if " << a << " then " << b << " else " << c << " end;";
    return alloc_string((char*) ss.str().data());
}
