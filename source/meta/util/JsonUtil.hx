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
	public static inline function stringify(value:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		return print(value, replacer, space);
	}

	public static function print(o:Dynamic, ?replacer:(key:Dynamic, value:Dynamic) -> Dynamic, ?space:String):String {
		var printer = new FunkyJson(replacer, space);
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
}