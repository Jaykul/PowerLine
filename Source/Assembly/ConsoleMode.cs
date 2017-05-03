using System;
using System.Runtime.InteropServices;

namespace PowerLine
{
	[Flags]
	enum ConsoleOutputModes : uint
	{
		ENABLE_PROCESSED_OUTPUT = 0x0001,
		ENABLE_WRAP_AT_EOL_OUTPUT = 0x0002,
		ENABLE_VIRTUAL_TERMINAL_PROCESSING = 0x0004,
		DISABLE_NEWLINE_AUTO_RETURN = 0x0008,
		ENABLE_LVB_GRID_WORLDWIDE = 0x0010,
	}

	public static class ConsoleMode
	{
		const int STD_OUTPUT_HANDLE = -11;
		public static void RestoreVirtualTerminal()
		{
			var outHandle = GetStdHandle(STD_OUTPUT_HANDLE);
			ConsoleOutputModes mode;
			if (!GetConsoleMode(outHandle, out mode))
			{
				mode = ConsoleOutputModes.ENABLE_PROCESSED_OUTPUT | ConsoleOutputModes.ENABLE_WRAP_AT_EOL_OUTPUT;
			}

			mode |= ConsoleOutputModes.ENABLE_VIRTUAL_TERMINAL_PROCESSING;
			SetConsoleMode(outHandle, (uint)mode);
		}

		[DllImport("kernel32.dll")]
		static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);

		[DllImport("kernel32.dll")]
		static extern bool GetConsoleMode(IntPtr hConsoleHandle, out ConsoleOutputModes mode);

		[DllImport("kernel32.dll", SetLastError = true)]
		static extern IntPtr GetStdHandle(int nStdHandle);
	}
}
