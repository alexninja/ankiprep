#include "Windows.h"
#include "..\conv.h"


void CopyToClipboard(char* str)
{
	std::string unescaped = Unescape(str);
	std::wstring utf16 = ToUtf16(unescaped);
	HGLOBAL hcopy = GlobalAlloc(GMEM_MOVEABLE, (utf16.size() + 1) * 2);
	if (hcopy == NULL) {
		CloseClipboard();
		throw "GlobalAlloc";
	}
	wchar_t* copy = (wchar_t*)GlobalLock(hcopy);
	wcscpy_s(copy, utf16.size() + 1, utf16.c_str());
	GlobalUnlock(hcopy);
	OpenClipboard(NULL);
	EmptyClipboard();
	SetClipboardData(CF_UNICODETEXT, hcopy);
	CloseClipboard();
}


int main(int argc, char* argv[])
{
	try
	{
		if (argc != 2) {
			throw "bad arg";
		}
		CopyToClipboard(argv[1]);
	}
	catch (char const* err)
	{
		printf("%s", err);
		return 1;
	}

	printf("COPIED");
	return 0;
}

