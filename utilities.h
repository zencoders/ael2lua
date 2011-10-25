#include <string>

static inline std::string& ltrim(std::string &s)
{
    s.erase(s.begin(), std::find_if(s.begin(), s.end(), std::not1(std::ptr_fun<int, int>(std::isspace))));
    return s;
}

static inline std::string& rtrim(std::string& s)
{
    s.erase(std::find_if(s.rbegin(), s.rend(), std::not1(std::ptr_fun<int, int>(std::isspace))).base(), s.end());
}
static inline std::string& trim(std::string& s)
{
    return ltrim(rtrim(s));
}

static inline std::vector<std::string>& split(const std::string& s, char delim, std::vector<std::string>& elems)
{
    std::stringstream ss(s);
    std::string item;
    while(std::getline(ss, item, delim))
    {
        elems.push_back(item);
    }
    return elems;
}

static inline std::vector<std::string> split(const std::string& s, char delim)
{
    std::vector<std::string> elems;
    return split(s, delim, elems);
}

std::string sday2iday(const std::string& s)
{
    if(s == "sun")
        return "1";
    else if(s == "mon")
        return "2";
    else if(s == "tue")
        return "3";
    else if(s == "wed")
        return "4";
    else if(s == "thu")
        return "5";
    else if(s == "fri")
        return "6";
    else if(s == "sat")
        return "7";
}

std::string smonth2imonth(const std::string& s)
{
    if(s == "jan")
        return "1";
    else if(s == "feb")
        return "2";
    else if(s == "mar")
        return "3";
    else if(s == "apr")
        return "4";
    else if(s == "may")
        return "5";
    else if(s == "jun")
        return "6";
    else if(s == "jul")
        return "7";
    else if(s == "aug")
        return "8";
    else if(s == "sep")
        return "9";
    else if(s == "oct")
        return "10";
    else if(s == "nov")
        return "11";
    else if(s == "dec")
        return "12";
}
