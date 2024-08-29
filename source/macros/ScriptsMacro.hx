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
			//BASE SOURCE CODE
			"meta", 'data', 'gameObjects',
			//HAXEUI
			"haxe.ui.backend.flixel.components", "haxe.ui.containers.dialogs", "haxe.ui.containers.menus", 
			"haxe.ui.containers.properties", "haxe.ui.core", "haxe.ui.components", "haxe.ui.containers",
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

		for(inc in [#if sys "sys", "openfl.net" #end]) {
			#if !hl
			Compiler.include(inc);
			#end
		}

		#if hl HashLinkFixer.init(); #end
		// Todo rewrite this to use if(Context.defined(""))
	}
}
#end