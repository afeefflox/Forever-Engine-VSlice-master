package meta.util;

//Stolen from Codename :///

import flixel.system.debug.log.LogStyle;
import flixel.system.frontEnds.LogFrontEnd;
import haxe.Log;
using meta.CoolUtil;

class LogsUtil 
{
    private static var __showing:Bool = false;
	public static var nativeTrace = Log.trace;

    public static function init() 
    {
        Log.trace = function(v:Dynamic, ?infos:Null<haxe.PosInfos>) {
			var data = [
				logText('${infos.fileName}:${infos.lineNumber}: ', CYAN),
				logText(Std.string(v))
			];

			if (infos.customParams != null) {
				for (i in infos.customParams) {
					data.push(
						logText("," + Std.string(i))
					);
				}
			}
			__showInConsole(prepareColoredTrace(data, TRACE));
		};

        LogFrontEnd.onLogs = function(data, style, fireOnce) {
            var prefix = "[FLIXEL]";
			var color:ConsoleColor = LIGHTGRAY;
			var level:Level = INFO;
			if (style == LogStyle.CONSOLE)  // cant place a switch here as these arent inline values  - Nex
			{
				prefix = "> ";
				color = WHITE;
				level = INFO;
			}
			else if (style == LogStyle.ERROR)
			{
				prefix = "[FLIXEL]";
				color = RED;
				level = ERROR;
			}
			else if (style == LogStyle.NORMAL)
			{
				prefix = "[FLIXEL]";
				color = WHITE;
				level = INFO;
			}
			else if (style == LogStyle.NOTICE)
			{
				prefix = "[FLIXEL]";
				color = GREEN;
				level = VERBOSE;
			}
			else if (style == LogStyle.WARNING)
			{
				prefix = "[FLIXEL]";
				color = YELLOW;
				level = WARNING;
			}

            
			var d:Dynamic = data;
			if (!(d is Array))
				d = [d];
			var a:Array<Dynamic> = d;
			var strs = [for(e in a) Std.string(e)];
			for(e in strs)
			{
				LogsUtil.trace('$prefix $e', level, color);
			}
        };
    }

    public static function prepareColoredTrace(text:Array<LogText>, level:Level = INFO) 
    {
        var time = Date.now();
		var superCoolText = [
            logText('[  '),
			logText('${Std.string(time.getHours()).addZeros(2)}:${Std.string(time.getMinutes()).addZeros(2)}:${Std.string(time.getSeconds()).addZeros(2)}', DARKMAGENTA),
			logText('  |'),
            switch (level)
			{
				case WARNING:
					logText('   WARNING   ', DARKYELLOW);
				case ERROR:
					logText('    ERROR    ', DARKRED);
				case TRACE:
					logText('    TRACE    ', GRAY);
				case VERBOSE:
					logText('   VERBOSE   ', DARKMAGENTA);
				default:
					logText(' INFORMATION ', CYAN);
			},
			logText('] ')
        ];
		for(k=>e in superCoolText)
			text.insert(k, e);
		return text;
    }

    public static function logText(text:String, color:ConsoleColor = LIGHTGRAY):LogText {
		return {
			text: text,
			color: color
		};
	}

	public static function __showInConsole(text:Array<LogText>) {
		#if sys
		while(__showing) {
			Sys.sleep(0.05);
		}
		__showing = true;
		for(t in text) {
			setConsoleColors(t.color);
			Sys.print(t.text);
		}
		setConsoleColors();
		Sys.print("\r\n");
		__showing = false;
		#else
		@:privateAccess
		nativeTrace([for(t in text) t.text].join(""));
		#end
	}

	public static function traceColored(text:Array<LogText>, level:Level = INFO)
		__showInConsole(prepareColoredTrace(text, level));

	public static function trace(text:String, level:Level = INFO, color:ConsoleColor = LIGHTGRAY) {
		traceColored([
			{
				text: text,
				color: color
			}
		], level);
	}

    public static function setConsoleColors(foregroundColor:ConsoleColor = NONE, ?backgroundColor:ConsoleColor = NONE) 
    {
        #if (windows && !hl)
		if(foregroundColor == NONE)
			foregroundColor = LIGHTGRAY;
		if(backgroundColor == NONE)
			backgroundColor = BLACK;

		var fg = cast(foregroundColor, Int);
		var bg = cast(backgroundColor, Int);
		WindowUtil.setConsoleColors((bg * 16) + fg);
		#elseif sys
		Sys.print("\x1b[0m");
		if(foregroundColor != NONE)
			Sys.print("\x1b[" + Std.int(consoleColorToANSI(foregroundColor)) + "m");
		if(backgroundColor != NONE)
			Sys.print("\x1b[" + Std.int(consoleColorToANSI(backgroundColor) + 10) + "m");
		#end
    }
}

enum abstract Level(Int) {
	var INFO = 0;
	var WARNING = 1;
	var ERROR = 2;
	var TRACE = 3;
	var VERBOSE = 4;
}

typedef LogText = {
	var text:String;
	var color:ConsoleColor;
}

enum abstract ConsoleColor(Int) {
	var BLACK = 0;
	var DARKBLUE = 1;
	var DARKGREEN = 2;
	var DARKCYAN = 3;
	var DARKRED = 4;
	var DARKMAGENTA = 5;
	var DARKYELLOW = 6;
	var LIGHTGRAY = 7;
	var GRAY = 8;
	var BLUE = 9;
	var GREEN = 10;
	var CYAN = 11;
	var RED = 12;
	var MAGENTA = 13;
	var YELLOW = 14;
	var WHITE = 15;

	var NONE = -1;
}