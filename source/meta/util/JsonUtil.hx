package meta.util;

import haxe.Json;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

class JsonUtil
{
    public static function checkJson<T>(defaults:T, ?input:T):T
	{
		var defaults:T = copyJson(defaults);
		if (input == null)
			return defaults;

		final props = Reflect.fields(defaults);
		for (prop in props) {
			if (Reflect.hasField(input, prop)) {
				var val = Reflect.field(input, prop);
				if (val == null)
					Reflect.setField(input, prop, Reflect.field(defaults, prop));
			}
			else
				Reflect.setField(input, prop, Reflect.field(defaults, prop));
		}

		return removeUnusedVars(defaults, input);
	}

	public static function removeUnusedVars<T>(defaults:T, input:T):T
	{
		final defProps = Reflect.fields(defaults);
		final inputProps = Reflect.fields(input);
		for (prop in inputProps) {
			if (!defProps.contains(prop))
				Reflect.deleteField(input, prop);
		}
		return input;
	}

	public static inline function copyJson<T>(c:T):T {
        return haxe.Unserializer.run(haxe.Serializer.run(c));
	}
}


class FunkyJson extends haxe.format.JsonPrinter
{
	var _ignoreTab:Array<String> = [];
	var _singleLineCheckNext:Bool = false;
	public static inline function stringify(value:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		return print(value, replacer, space);
	}

	public static function print(o:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		var printer = new FunkyJson(replacer, space);
		printer.write("", o);
		return printer.buf.toString();
	}

	public static function printAlt(o:Dynamic, ?ignoreTab:Array<String>):String
	{
		var printer = new FunkyJson(null, '\t');
		if(ignoreTab != null) printer._ignoreTab = ignoreTab;
		printer.write("", o);
		return printer.buf.toString();
	}
	
	override function write(k:Dynamic, v:Dynamic) {
		if (replacer != null)
			v = replacer(k, v);
		switch (Type.typeof(v)) {
			case TUnknown:
				add('"???"');
			case TObject:
				objString(v);
			case TInt:
				add(#if (jvm || hl) Std.string(v) #else v #end);
			case TFloat:
				add(Math.isFinite(v) ? Std.string(v) : 'null');
			case TFunction:
				add('"<fun>"');
			case TClass(c):
				if (c == String)
					quote(v);
				else if (c == Array) {
					var v:Array<Dynamic> = v;
					addChar('['.code);

					var len = v.length;
					var last = len - 1;
					for (i in 0...len) {
						if (i > 0)
							addChar(','.code)
						else
							nind++;
						
						var type = Type.typeof(cast v[i]);
						var clean = true;
						switch (type) {
							case TFloat | TInt | TClass(String): clean = false;
							default:
						}
						if (clean) {
							newl();
							ipad();
						}
						write(i, v[i]);
						if (i == last) {
							nind--;
							if (clean) {
								newl();
								ipad();
							}
						}
					}
					addChar(']'.code);
				} else if (c == haxe.ds.StringMap) {
					var v:haxe.ds.StringMap<Dynamic> = v;
					var o = {};
					for (k in v.keys())
						Reflect.setField(o, k, v.get(k));
					objString(o);
				} else if (c == Date) {
					var v:Date = v;
					quote(v.toString());
				} else
					classString(v);
			case TEnum(_):
				var i = Type.enumIndex(v);
				add(Std.string(i));
			case TBool:
				add(#if (php || jvm || hl) (v ? 'true' : 'false') #else v #end);
			case TNull:
				add('null');
		}
	}

	override function fieldsString(v:Dynamic, fields:Array<String>)
		fieldsStringEx(v, fields);

	function fieldsStringEx(v:Dynamic, fields:Array<String>, ?mapCheck:Bool = false)
	{
		addChar('{'.code);
		var len = fields.length;
		var last = len - 1;

		var hasArrayInsideIt:Bool = false;
		if(_singleLineCheckNext)
		{
			for (subv in Reflect.fields(v))
			{
				switch(Type.typeof(subv))
				{
					case TObject, TClass(Array):
						hasArrayInsideIt = true;
						break;
					default:
				}
			}
		}

		var usedMapCheck:Bool = false;
		var first = true;
		for (i in 0...len) {
			var f = fields[i];
			var value = Reflect.field(v, f);
			if (Reflect.isFunction(value))
				continue;
			if (first)
			{
				nind++;
				first = false;
			}
			else
			{
				addChar(','.code);
				if(_singleLineCheckNext && !hasArrayInsideIt) addChar(' '.code);
			}

			var _mapCheck = mapCheck;
			if(_mapCheck)
			{
				switch(Type.typeof(value))
				{
					case TObject, TClass(Array), TClass(haxe.ds.StringMap):
						usedMapCheck = true;
					default:
						_mapCheck = false;
				}
			}

			if(!_singleLineCheckNext || hasArrayInsideIt || _mapCheck || usedMapCheck)
			{
				newl();
				ipad();
			}
			quote(f);
			addChar(':'.code);
			if (pretty)
				addChar(' '.code);

			var doContain:Bool = _ignoreTab.contains(f);
			if(doContain) _singleLineCheckNext = true;
			write(f, value);
			if(doContain) _singleLineCheckNext = false;

			if (i == last) {
				nind--;
				if(!_singleLineCheckNext)
				{
					newl();
					ipad();
				}
			}
		}
		if(hasArrayInsideIt || usedMapCheck)
		{
			newl();
			ipad();
		}
		addChar('}'.code);
	}
}