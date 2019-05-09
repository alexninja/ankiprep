#pragma once
#include <string>

inline char FromHex(wchar_t ch)
{
    if (ch >= '0' && ch <= '9')
        return (char)(ch - '0');
    if (ch >= 'A' && ch <= 'F')
        return (char)(ch - 'A' + 10);
    if (ch >= 'a' && ch <= 'f')
        return (char)(ch - 'a' + 10);
    return -1;
}

inline std::string Unescape(std::string const& str)
{
    std::string ret;
    for (size_t i = 0; i < str.size(); i++)
    {
        const char* p = &str[i];
        if (str[i] == '%' && i < (str.size() - 2))
        {
            char nib1 = FromHex(str[i+1]);
            char nib2 = FromHex(str[i+2]);
            if (nib1 != -1 && nib2 != -1)
            {
                ret += (char) (nib1 * 16 + nib2);
                i += 2;
                continue;
            }
        }
        ret += str[i];
    }
    return ret;
}

inline std::wstring ToUtf16(std::string const& str)
{
    std::wstring ret;
    int sz = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, 0, 0);
    if (sz > 0)
    {
        wchar_t* buf = new wchar_t[sz];
        RtlZeroMemory(buf, sz*2);
        sz = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), -1, buf, sz);
        if (sz == 0) {
            throw "MultiByteToWideChar";
        }
        ret = buf;
        delete buf;
    }
    return ret;
}
