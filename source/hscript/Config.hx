package hscript;

class Config {
	// Runs support for custom classes in these
	public static final ALLOWED_CUSTOM_CLASSES = [
	];

	// Runs support for abstract support in these
	public static final ALLOWED_ABSTRACT_AND_ENUM = [
        "flixel",
		"openfl",
        
        //BASE GAME SOURCE
        "meta", 'data', 'gameObjects', 'audio', 'graphics', 
        //Funkin Vis
		"funkin.vis",
        //HAXEUI
        "haxe.ui",
        //BASE HAXE
        "DateTools", "EReg", "Lambda", "StringBuf", "haxe.crypto", "haxe.display", "haxe.exceptions", "haxe.extern", "scripting"
	];

	// Incase any of your files fail
	// These are the module names
	public static final DISALLOW_CUSTOM_CLASSES = [
	];

	public static final DISALLOW_ABSTRACT_AND_ENUM = [
	];
}