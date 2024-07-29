package macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Compiler;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class ScriptsMacro {
	public static function addAdditionalClasses() {
		for(inc in [
			"data", "gameObjects", "meta",
			// FLIXEL
			"flixel.util", "flixel.ui", "flixel.tweens", "flixel.tile", "flixel.text",
			"flixel.system", "flixel.sound", "flixel.path", "flixel.math", "flixel.input",
			"flixel.group", "flixel.graphics", "flixel.effects", "flixel.animation",
			// FLIXEL ADDONS
			"flixel.addons.api", "flixel.addons.display", "flixel.addons.effects", "flixel.addons.ui",
			"flixel.addons.plugin", "flixel.addons.text", "flixel.addons.tile", "flixel.addons.transition",
			"flixel.addons.util",
			// BASE HAXE
			"DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting"
		])
		Compiler.include(inc);

		#if hl HashLinkFixer.init(); #end
		// Todo rewrite this to use if(Context.defined(""))
	}
}
#end