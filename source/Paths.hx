package;

/*
	Aw hell yeah! something I can actually work on!
 */
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import meta.CoolUtil;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import sys.FileSystem;
import sys.io.File;

class Paths
{
	// Here we set up the paths class. This will be used to
	// Return the paths of assets and call on those assets as well.
	inline public static var SOUND_EXT = "ogg";

	// level we're loading
	static var currentLevel:String;

	// set the current level top the condition of this function if called
	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.${Constants.EXT_SOUND}',
		'assets/music/foreverMenu.${Constants.EXT_SOUND}',
		'assets/music/breakfast.${Constants.EXT_SOUND}',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var counter:Int = 0;
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj = currentTrackedAssets.get(key);
				if (obj != null)
				{
					obj.persist = false;
					obj.destroyOnNoUse = true;
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture)
					{
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key))
					{
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
					#if GARBAGE_COLLECTOR_INFO
					trace('removed $key, ' + (isTexture ? 'is a texture' : 'is not a texture'));
					#end
					obj.destroy();
					currentTrackedAssets.remove(key);
					counter++;
				}
			}
		}
		#if GARBAGE_COLLECTOR_INFO trace('removed $counter assets'); #end
		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			final obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	public static function returnGraphic(key:String, ?library:String, ?textureCompression:Bool = false)
	{
		var path = getPath('images/$key.png', IMAGE, library);
		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(key))
			{
				var bitmap = OpenFlAssets.getBitmapData(path);
				var newGraphic:FlxGraphic;
				if (textureCompression)
				{
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				newGraphic.persist = true;
				newGraphic.destroyOnNoUse = false;
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		trace('tried to load graphic "$key" which is returning null');
		return null;
	}

	public static function returnSound(path:String, key:String, ?library:String)
	{
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.${Constants.EXT_SOUND}', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath));
		localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	//
	inline public static function getPath(file:String, type:AssetType, ?library:Null<String>)
	{
		if (library != null)
			return getLibraryPath(file, library);

		var levelPath = getLibraryPathForce(file, "shared");
		if (exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library/$file';
	}

	inline static function getPreloadPath(file:String)
	{
		var returnPath:String = 'assets/$file';
		if (!exists(returnPath))
			returnPath = CoolUtil.swapSpaceDash(returnPath);
		return returnPath;
	}

	inline static public function exists(key:String, ?type:AssetType) {
		if(OpenFlAssets.exists(key, type))
			return true;
		return false;
	}

	inline static public function animateAtlas(key:String, ?library:String) 
	{
		return getPath('images/$key', IMAGE, library);
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('$key.json', TEXT, library);
	}

	inline static public function songJson(song:String, secondSong:String, ?library:String)
		return getPath('songs/${song.toLowerCase()}/${secondSong.toLowerCase()}.json', TEXT, library);

	static public function sound(key:String, ?library:String):Dynamic
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Dynamic
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String, ?suffix:String = ""):Any
	{
		var path = '${CoolUtil.swapSpaceDash(song.toLowerCase())}/Voices$suffix';
		return returnSound('songs', path);
	}

	inline static public function inst(song:String, ?suffix:String = ""):Any
	{
		var path = '${CoolUtil.swapSpaceDash(song.toLowerCase())}/Inst$suffix';
		return returnSound('songs', path);
	}

	inline static public function songPaths(song:String, key:String, ?suffix:String = "")
	{
		return 'songs/${CoolUtil.swapSpaceDash(song.toLowerCase())}/$key$suffix.${Constants.EXT_SOUND}';
	}

	inline static public function soundPaths(key:String, ?library:String)
	{
		return getPath('sound/$key.${Constants.EXT_SOUND}', SOUND, library);
	}

	inline static public function musicPaths(key:String, ?library:String)
	{
		return getPath('music/$key.${Constants.EXT_SOUND}', SOUND, library);
	}

	
	inline static public function imagePaths(key:String, ?library:String)
	{
		return getPath('images/$key.png', TEXT, library);
	}

	inline static public function image(key:String, ?library:String, ?textureCompression:Bool = false)
	{
		var returnAsset:FlxGraphic = returnGraphic(key, library, textureCompression);
		return returnAsset;
	}

	inline static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	public static function getAtlas(key:String, ?library:String):FlxAtlasFrames {
		if(exists(json('images/$key', library), TEXT))
			return getAsepriteAtlas(key, library);
		else if(exists(txt('images/$key', library), TEXT))
			return getPackerAtlas(key, library);

		return getSparrowAtlas(key, library);
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
