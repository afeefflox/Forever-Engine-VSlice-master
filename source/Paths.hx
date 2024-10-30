package;

/*
	Aw hell yeah! something I can actually work on!
 */
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	inline public static var SOUND_EXT = "ogg";

	// level we're loading
	static var currentLevel:Null<String> = null;
	public static function setCurrentLevel(name:Null<String>):Void
	{
		if (name == null)
			currentLevel = null;
		else
			currentLevel = name.toLowerCase();
	}

	public static function stripLibrary(path:String):String
	{
		var parts:Array<String> = path.split(':');
		if (parts.length < 2) return path;
		return parts[1];	
	}

	public static function getLibrary(path:String):String
	{
		var parts:Array<String> = path.split(':');
		if (parts.length < 2) return 'preload';
		return parts[0];
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = getLibraryPathForce(file, currentLevel);
			if (exists(levelPath, type)) return levelPath;
		}

		var levelPath = getLibraryPathForce(file, "shared");
		if (exists(levelPath, type)) return levelPath;

		return getPreloadPath(file);
	}

	inline public static function getPathAlt(file:String, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		var levelPath = getLibraryPathForce(file, "shared");
		if (exists(levelPath))
			return levelPath;

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);

	inline static function getLibraryPathForce(file:String, library:String)
		return 'assets/$library/$file';

	inline static function getPreloadPath(file:String)
		return 'assets/$file';

	inline static public function exists(key:String, ?type:AssetType) {
		if(OpenFlAssets.exists(key, type))
			return true;
		return false;
	}

	inline static public function getFileContent(key:String) {
		if(OpenFlAssets.exists(key, TEXT))
			return OpenFlAssets.getText(key);
		return null;
	}

	inline static public function animateAtlas(key:String, ?library:String) 
		return getPath('images/$key', IMAGE, library);

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('$key.txt', TEXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('$key.xml', TEXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('$key.json', TEXT, library);

	inline static public function ui(key:String, ?library:String)
		return getPath('ui/$key.xml', TEXT, library);

	inline static public function video(key:String, ?library:String)
		return getPathAlt('videos/$key.${Constants.EXT_VIDEO}', library);

	public static function frag(key:String, ?library:String):String
		return getPath('shaders/$key.frag', TEXT, library);
		
	public static function vert(key:String, ?library:String):String
		return getPath('shaders/$key.vert', TEXT, library);

	public static function shader(key:String, ?library:String):String
	{
		if(exists(vert(key, library), TEXT))
			return vert(key, library);
		return frag(key, library);
	}

	static public function sound(key:String, ?library:String)
		return getPath('sounds/$key.${Constants.EXT_SOUND}', SOUND, library);

	inline static public function music(key:String, ?library:String)
		return getPath('music/$key.${Constants.EXT_SOUND}', SOUND, library);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function voices(song:String, ?suffix:String = "")
	{
		if (suffix == null) suffix = '';
		return getPath('songs/${song.toLowerCase()}/Voices$suffix.${Constants.EXT_SOUND}', SOUND);
	}

	inline static public function inst(song:String, ?suffix:String = "")
	{
		if (suffix == null) suffix = '';
		return getPath('songs/${song.toLowerCase()}/Inst$suffix.${Constants.EXT_SOUND}', SOUND);
	}

	inline static public function image(key:String, ?library:String)
		return getPath('images/$key.png', IMAGE, library);

	inline static public function font(key:String)
		return 'assets/fonts/$key';

	public static function getAtlas(key:String, ?library:String):FlxAtlasFrames {
		if(exists(json('images/$key', library), TEXT))
			return getAsepriteAtlas(key, library);
		else if(exists(xml('images/$key', library), TEXT))
			return getSparrowAtlas(key, library);

		return getPackerAtlas(key, library);
	}

	public static function getExistAtlas(key:String, ?library:String):Bool {
		if(exists(json('images/$key', library), TEXT))
			return true;
		else if(exists(txt('images/$key', library), TEXT))
			return true;
		else if(exists(xml('images/$key', library), TEXT))
			return true;

		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		return (FlxAtlasFrames.fromSparrow(image(key, library), xml('images/$key', library)));
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		return (FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), txt('images/$key', library)));
	}

	inline static public function getAsepriteAtlas(key:String, ?library:String)
	{
		return (FlxAtlasFrames.fromAseprite(image(key, library), json('images/$key', library)));
	}
}

enum abstract PathsFunction(String)
{
  var MUSIC;
  var INST;
  var VOICES;
  var SOUND;
}
