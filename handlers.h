#ifndef _HANDLERS_H_
#define _HANDLERS_H_

#include "common.h"

/**
 * Structure used to describe temporal data. It is mainly used to translate ifTime constructs.
**/
typedef struct 
{
    char* beginHour;
    char* endHour;
    char* beginMinutes;
    char* endMinutes;
    char* beginDay;
    char* endDay;
    char* beginDOM;
    char* endDOM;
    char* beginMonth;
    char* endMonth;

    void destroyAll()
    {
        destroy_string(beginHour);
        destroy_string(endHour);
        destroy_string(beginMinutes);
        destroy_string(endMinutes);
        destroy_string(beginDay);
        destroy_string(endDay);
        destroy_string(beginDOM);
        destroy_string(endDOM);
        destroy_string(beginMonth);
        destroy_string(endMonth);
    }
} TimeStruct;

/**
 * Method used to convert a time representation (TimeStruct) into a string containing a ifTimeHead construct.
 * @param ts the TimeStruct to convert
 * @return a string representing an ifTimeHead construct
**/
std::string time2iftime(TimeStruct* ts);

/**
 * Method used to fill a TimeStruct object.
 * @param t1 string containing the begin hour part of the time representation
 * @param t2 string containing the begin minute part and the end hour part of the time representation; separated by "-" symbol.
 * @param t3 string containin the end minute part of the time representation
 * @param day string containing the day or the day range
 * @param md string containing the day of month or the day of month range
 * @param m string containing the month or the month range
 * @param ts The resulting TimeStruct
**/
void handleTimes(char* t1, char* t2, char* t3, char* day, char* md, char* m, TimeStruct* ts);

void handleTimes(char* time, char* day, char* md, char* m, TimeStruct* ts);

char* handleIf(char* head, char* statement);

char* handleIfElse(char* head, char* statement, char* statement2);

char* handleIncludedName(char* name);

char* handleMacroDef(char* name,char* arglist, char* stats);

char* handleContext(char* name,char* content);

void store_hint(char* h);
#endif
