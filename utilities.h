#ifndef _UTILITIES_H_
#define _UTILITIES_H_
#include <string>
#include <vector>

/**
 * Method used to remove spaces preceding the string
 * @param the string to trim
 * @return the newwly created string
**/
std::string& ltrim(std::string &s);

/**
 * Method used to remove spaces following the string
 * @param the string to trim
 * @return the newwly created string
**/
std::string& rtrim(std::string& s);

/**
 * Method used to remove spaces following and preceding the string
 * @param the string to trim
 * @return the newwly created string
**/
std::string& trim(std::string& s);

/**
 * Split a string using the passed delimiter and put parts into the passed vector
 * @param s The string to split
 * @param delim The delimitation character
 * @param elems The vector to fill
 * @return the same vector passed in input
**/
std::vector<std::string>& split(const std::string& s, char delim, std::vector<std::string>& elems);

/**
 * Split a string using the given delimiter
 * @param s the string to split
 * @param delim the delimitation character
 * @return a vector containing all string parts
**/
std::vector<std::string> split(const std::string& s, char delim);

/**
 * Method used to convert a day representation from string to integer (Mon -> 1, ecc...)
 * @param s the string containing the day name
 * @return a string containing the integer represenation of the day
**/
std::string sday2iday(const std::string& s);

/**
 * Method used to convert a month representation from string to integer (Jun -> 6, ecc...)
 * @param s the string containing the month name
 * @return a string containing the integer represenation of the month
**/
std::string smonth2imonth(const std::string& s);

/**
 * Checks if the string is a valid number for the specified base
 * @param pszInput The input string
 * @param nNumberBase The numeric base used to do the check
 * @return true if the string is valid, false otherwise
**/
bool isNumeric( const char* pszInput, int nNumberBase );

/**
 * Method used to split a string using spaces as delimiters
 * @param s The string to split
 * @return a vector containing all string parts
**/
std::vector<std::string> string_split(const std::string& s);
#endif
