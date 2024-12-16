package macros;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class Macros {
	public static function addAdditionalClasses() {
		for(inc in [
            //BASE GAME
            "audio", "data", "gameObjects", "graphics", "meta", "funkin", //for other library stuff
			// FLIXEL
			"flixel.util", "flixel.ui", "flixel.tweens", "flixel.tile", "flixel.text",
			"flixel.system", "flixel.sound", "flixel.path", "flixel.math", "flixel.input",
			"flixel.group", "flixel.graphics", "flixel.effects", "flixel.animation",
			// FLIXEL ADDONS
			"flixel.addons.api", "flixel.addons.display", "flixel.addons.effects", "flixel.addons.ui",
			"flixel.addons.plugin", "flixel.addons.text", "flixel.addons.tile", "flixel.addons.transition",
			"flixel.addons.util",
			// OTHER LIBRARIES & STUFF
            "hxvlc.flixel", "hxvlc.openfl",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting"
		])
			Compiler.include(inc);

		var isHl = Context.defined("hl");

		if(Context.defined("sys")) {
			for(inc in ["sys", "openfl.net"]) {
				if(!isHl)
					Compiler.include(inc);
			}
		}
	}

	public static function initMacros() {
		if(Context.defined("hl"))
			HashLinkFixer.init();
	}
}
#end