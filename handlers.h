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

/**
 * Method used to fill a TimeStruct object.
 * @param time string containing the time part of the representation
 * @param day string containinng the day or the day range
 * @param md string containing the day of month or the day of month range
 * @param m string containing the month or the month range
 * @param ts the resulting TimeStruct
**/
void handleTimes(char* time, char* day, char* md, char* m, TimeStruct* ts);

/**
 * Method used to build a complete if block
 * @param head string containing the if head
 * @param statement string containing the if body
 * @return string containing the complete if block
**/
char* handleIf(char* head, char* statement);

/**
 * Method used to build a complete if block with an else statement
 * @param head string containing the if head
 * @param statement string containing the if body
 * @param statement2 string containing the else body
 * @return string containing the complete if block
**/
char* handleIfElse(char* head, char* statement, char* statement2);

/**
 * Method used to build the included name for a list of inclusions. This method works
 * also to translate temporal inclusions.
 * @param name The name of the file to include
 * @param string containing the obtained new include name equivalent
**/
char* handleIncludedName(char* name);

/**
 * Method used to build a macro block
 * @param name The macro name
 * @param arglist The list of arguments passed to the macro
 * @param stats Statements composing the macro body
 * @return string representing the macro translated
**/
char* handleMacroDef(char* name,char* arglist, char* stats);

/**
 * Method used to build a context block
 * @param name The name of the context block
 * @param content The content of the context block
 * @return string representing the context translated
**/
char* handleContext(char* name,char* content);

/**
 * Method used to annotate al encountered hints in code. This system is used to avoid a supplementary pass of the parser
 * @param h The hint name
**/
void store_hint(char* h);
#endif
