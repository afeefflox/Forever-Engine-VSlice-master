package meta;

import openfl.utils.Assets;
import meta.state.PlayState;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CoolUtil
{
	public static var difficultyLength = Constants.DEFAULT_DIFFICULTY_LIST.length;

	public static inline function difficultyFromNumber(number:Int):String
	{
		return Constants.DEFAULT_DIFFICULTY_LIST[number];
	}

	public static inline function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static inline function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static inline function swapSpaceDash(string:String):String
	{
		return string.contains('-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static inline function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		if(Paths.exists(path, TEXT))
		{
			daList = Assets.getText(path).trim().split('\n');
			for (i in 0...daList.length)
				daList[i] = daList[i].trim();
		}
		trace('$path: $daList');
		return daList != null && daList.length > 0 ? daList : [];
	}

	public static inline function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		var libraryArray:Array<String> = [];

		#if sys
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (folder in unfilteredLibrary)
		{
			if (!folder.contains('.'))
				libraryArray.push(folder);
		}
		//trace(libraryArray);
		#end

		return libraryArray;
	}

	public static inline function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split('--'));
		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		return [for (i in min...max) i];
	}
	
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setFieldDefault<T>(v:Dynamic, name:String, defaultValue:T):T {
		if (Reflect.hasField(v, name)) {
			var f:Null<Dynamic> = Reflect.field(v, name);
			if (f != null)
				return cast f;
		}
		Reflect.setField(v, name, defaultValue);
		trace('Value: ${v}, Name: ${name}, DefaultValue: ${defaultValue}');
		return defaultValue;
	}

	public static inline function addZeros(str:String, num:Int) {
		while(str.length < num) str = '0${str}';
		return str;
	}
}
