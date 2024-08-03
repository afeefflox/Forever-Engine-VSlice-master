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