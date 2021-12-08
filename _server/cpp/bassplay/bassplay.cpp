#include "bass.h"
#include "..\conv.h"

void Error(const char *text)
{
	printf("[bassplay.exe] BASS Error(%d): %s\n", BASS_ErrorGetCode(), text);
	BASS_Free();
	exit(0);
}

void play(std::wstring& filename, DWORD volume)
{
	DWORD chan, act;

	if (HIWORD(BASS_GetVersion()) != BASSVERSION)
	{
		printf("[bassplay.exe] An incorrect version of BASS was loaded");
		return;
	}

	if (!BASS_Init(-1, 44100, 0, 0, NULL))
	{
		Error("[bassplay.exe] Can't initialize device");
	}

	if (GetFileAttributesW(filename.c_str()) == -1)
	{
		wprintf(L"[bassplay.exe] File Not Found: %s\n", filename.c_str());
		return;
	}

	wprintf(L"[bassplay.exe] Playing (%d): %s\n", volume, filename.c_str());

	chan = BASS_StreamCreateFile(FALSE, filename.c_str(), 0, 0, BASS_UNICODE);

	BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, volume);

	BASS_ChannelPlay(chan, FALSE);

	while (act = BASS_ChannelIsActive(chan))
	{
		Sleep(50);
	}

	BASS_Free();
}


int main(int argc, char** argv)
{
	DWORD volume = atoi(argv[1]);

	std::string unescaped = Unescape(argv[2]);
	std::wstring utf16 = ToUtf16(unescaped);

	play(utf16, volume);
}
