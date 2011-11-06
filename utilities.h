#ifndef _UTILITIES_H_
#define _UTILITIES_H_
#include <string>

std::string& ltrim(std::string &s);

std::string& rtrim(std::string& s);

std::string& trim(std::string& s);

std::vector<std::string>& split(const std::string& s, char delim, std::vector<std::string>& elems);

std::vector<std::string> split(const std::string& s, char delim);

std::string sday2iday(const std::string& s);

std::string smonth2imonth(const std::string& s);

bool isNumeric( const char* pszInput, int nNumberBase );
#endif
