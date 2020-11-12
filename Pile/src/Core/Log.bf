using System;
using System.Collections;
using System.IO;

namespace Pile
{
	public static class Log
	{
#if PILE_LONG_LOG_RECORD
		public const int32 LOG_RECORD_COUNT = 128;
#else
		public const int32 LOG_RECORD_COUNT = 16;
#endif
		
		public enum Types
		{
			case Message;
			case Warning;
			case Error;

			public ConsoleColor ToColor()
			{
				switch (this)
				{
				case .Message: return .White;
				case .Warning: return .Yellow;
				case .Error:   return .Red;
				}
			}

			public override void ToString(String strBuffer)
			{
				switch (this)
				{
				case .Message: strBuffer.Append("INFO");
				case .Warning: strBuffer.Append("WARN");
				case .Error:   strBuffer.Append("FAIL");
				}
			}
		}

		const String SEPERATOR = ": ";

		public delegate void LineCallback(Types type, String message);
		public static Event<LineCallback> OnLine;

#if DEBUG // Different defaults
		public static bool PrintToConsole = true;
		public static bool SaveOnError = false;
#else
		public static bool PrintToConsole = false;
		public static bool SaveOnError = true;
#endif

		static bool discontinued;
		static int writeIndex = 0;

		static readonly String buf = new String(32) ~ delete _;
		static readonly String logBuf = new String(64) ~ delete _;
		static readonly String[] record = new String[LOG_RECORD_COUNT];

		static String logPath ~ DeleteNotNull!(_); // Only assigned when first used

		static this()
		{
			for (int i = 0; i < LOG_RECORD_COUNT; i++)
				record[i] = new String(64);
		}

		static ~this()
		{
			for (int i = 0; i < LOG_RECORD_COUNT; i++)
				delete record[i];
			delete record;
		}

		// Logging shorthands
#if PILE_DISABLE_LOG_MESSAGES
		[SkipCall]
#endif
		public static void Message(String message) => Log(Types.Message, message);
#if PILE_DISABLE_LOG_MESSAGES
		[SkipCall]
#endif
		public static void Message(Object message) => Log(Types.Message, message);
#if PILE_DISABLE_LOG_WARNINGS
		[SkipCall]
#endif
		public static void Warning(String message) => Log(Types.Warning, message);
#if PILE_DISABLE_LOG_WARNINGS
		[SkipCall]
#endif
		public static void Warning(Object message) => Log(Types.Warning, message);
		public static void Error(String message)
		{
			Log(Types.Error, message);
			
			if (SaveOnError)
			{
				if (logPath == null)
					CreateLogPathString();

				SaveToFile(logPath);
			}
		}
		public static void Error(Object message)
		{
			Log(Types.Error, message);

			if (SaveOnError)
			{
				if (logPath == null)
					CreateLogPathString();

				SaveToFile(logPath);
			}
		}

		static void CreateLogPathString()
		{
			logPath = new String();
			Path.InternalCombine(logPath, Core.System.UserPath, @"log.txt");
		}	

		// Actually log lines

		static void Log(Types type, String message)
		{
			// Write type
			type.ToString(buf);
			Append(buf, type.ToColor());
			buf.Clear();

			Append(SEPERATOR, ConsoleColor.DarkGray);

			// Write message
			Append(message);

			AppendLineBreak();

			OnLine(type, message);
		}

		static void Log(Types type, Object message)
		{
			// Write type
			type.ToString(buf);
			Append(buf, type.ToColor());
			buf.Clear();

			Append(SEPERATOR, ConsoleColor.DarkGray);

			// Write message
			message.ToString(buf);
			Append(buf);

			AppendLineBreak();

			OnLine(type, buf);
			buf.Clear();
		}

		static void Append(String text, ConsoleColor color = ConsoleColor.White)
		{
			if (PrintToConsole)
			{
				Console.ForegroundColor = color;
				Console.Write(text);
			}

			logBuf.Append(text);
		}

		static void AppendLineBreak()
		{
			if (PrintToConsole)
				Console.WriteLine();

			AppendRecord();
		}

		// Record stuff

		static void AppendRecord()
		{
			// Take logBuf and put its contents into record array
			record[writeIndex].Set(logBuf);
			logBuf.Clear();

			// Move writeIndex
			if (writeIndex + 1 < LOG_RECORD_COUNT)
				writeIndex++;
			else writeIndex = 0;
		}

		static void ClearRecord()
		{
			// Indicate that is is not the full log record
			discontinued = true;

			// Clear
			for (var string in record)
				string.Clear();
			writeIndex = 0;
		}

		// Save log record (and clear record)

		public static void SaveToFile(String filePath)
		{
			var directory = scope String();
			Runtime.Assert(Path.GetDirectoryPath(filePath, directory) case .Ok, "Couldn't append log to file, invalid path");

			if (directory.Length != 0 && !Directory.Exists(directory))
			{
				if (Directory.CreateDirectory(directory) case .Err(let res)) Runtime.FatalError(scope String()..AppendF("Couldn't append log to file, couldn't create missing directory: {}", res));
			}

			let fileLog = scope String();
			if (discontinued) fileLog.Append("CONTINUES LOG FROM BELOW");
			else fileLog.Append("START OF LOG OUTPUT");

			fileLog.Append(Environment.NewLine);
			DateTime.UtcNow.ToString(fileLog, "yyyy-MM-dd\"T\"HH:mm:ss\" UTC (Local offset: \"");
			TimeZoneInfo.Local.GetUtcOffset(DateTime.Now).Hours.ToString(fileLog);
			fileLog..Append(")").Append(Environment.NewLine);

			// Save and empty log

			// writeIndex is where we *would* write next, and since the newest output (index before this)
			// is printed last, we start here at the (if existant) oldest and go around once
			for (int x = 0, int i = writeIndex; x < LOG_RECORD_COUNT; x++, i = (i + 1) < LOG_RECORD_COUNT ? i + 1 : 0) // Since we start anywhere in the array, we will need to wrap i
			{
				// Skip empty/cleared lines
				if (record[i].Length == 0)
					continue;

				// Append string
				fileLog.Append(record[i]);
				fileLog.Append(Environment.NewLine);
			}
			ClearRecord();

			// Append possibly existing file
			if (File.Exists(filePath))
			{
				fileLog.Append(Environment.NewLine);

				var existingFile = scope String();
				if (File.ReadAllText(filePath, existingFile, true) case .Err(let res)) Runtime.FatalError(scope String()..AppendF("Couldn't append log to file, couldn't read existing file: {}", res));

				fileLog.Append(existingFile);
			}

			// Write
			Runtime.Assert(File.WriteAllText(filePath, fileLog) case .Ok, "Couldn't append log to file, couldn't write file");
		}
	}
}
