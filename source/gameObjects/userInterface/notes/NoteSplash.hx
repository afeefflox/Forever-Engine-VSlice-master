package gameObjects.userInterface.notes;

import flixel.math.FlxMath;
import flixel.FlxG;
import meta.data.dependency.FNFSprite;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.state.PlayState;
import meta.CoolUtil;
typedef NoteSplashConfig = {
	anim:String,
	minFps:Int,
	maxFps:Int,
	offsets:Array<Array<Float>>
}

/**
	Create the note splashes in week 7 whenever you get a sick!
**/
class NoteSplash extends FNFSprite
{
	public static var configs:Map<String, NoteSplashConfig> = new Map<String, NoteSplashConfig>();
	private var _textureLoaded:String = null;
	private var _configLoaded:String = null;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	public function new(x:Float = 0, y:Float = 0) 
	{
		super(x, y);
		visible = false;
		alpha = 0.6;

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		else skin = 'noteSplashes';
		precacheConfig(skin, PlayState.assetModifier);
		_configLoaded = skin;
		scrollFactor.set();
	}

	override function destroy()
	{
		configs.clear();
		super.destroy();
	}

	public static var maxAnims:Int = 2;
	public function setupNoteSplash(x:Float, y:Float, direction:Int = 0, assetModifier:String = 'base', ?note:Note = null) 
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);

		var texture:String = null;
		if(note != null && note.noteSplashData.texture != null) 
			texture = note.noteSplashData.texture;
		else if(PlayState.SONG != null && PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) 
			texture = PlayState.SONG.splashSkin;
		else texture = 'noteSplashes';

		var config:NoteSplashConfig = null;
		if(_textureLoaded != texture)
			config = loadAnims(texture, assetModifier);
		else
			config = precacheConfig(_configLoaded, assetModifier);
		
		if (assetModifier == 'pixel')
		{
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			antialiasing = false;
		}
		else
		{
			scale.set(1, 1);
			antialiasing = true;
		}
			

		if(note != null) alpha = note.noteSplashData.alpha;
		if(note != null && note.noteSplashData.antialiasing != true) antialiasing = note.noteSplashData.antialiasing;
		offset.set(10, 10);
		

		var animNum:Int = FlxG.random.int(1, maxAnims);
		playAnim('note' + direction + '-' + animNum, true);

		var minFps:Int = 22;
		var maxFps:Int = 26;
		if(config != null)
		{
			var animID:Int = direction + ((animNum - 1) * colArray.length);
			//trace('anim: ${animation.curAnim.name}, $animID');
			var offs:Array<Float> = config.offsets[FlxMath.wrap(animID, 0, config.offsets.length-1)];
			offset.x += offs[0];
			offset.y += offs[1];
			minFps = config.minFps;
			maxFps = config.maxFps;
		}
		else
		{
			offset.x += -58;
			offset.y += -55;
		}
		alpha = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.6;

		if(animation.curAnim != null)
			animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
	}

	public static function precacheConfig(skin:String, assetModifier:String = 'base')
	{
		if(configs.exists(skin)) return configs.get(skin);
		var path:String = Paths.txt('images/noteskins/notes/default/$assetModifier/$skin');
		var configFile:Array<String> = CoolUtil.coolTextFile(path);
		if(configFile.length < 1) return null;
		
		var framerates:Array<String> = configFile[1].split(' ');
		var offs:Array<Array<Float>> = [];
		for (i in 2...configFile.length)
		{
			var animOffs:Array<String> = configFile[i].split(' ');
			offs.push([Std.parseFloat(animOffs[0]), Std.parseFloat(animOffs[1])]);
		}

		var config:NoteSplashConfig = {
			anim: configFile[0],
			minFps: Std.parseInt(framerates[0]),
			maxFps: Std.parseInt(framerates[1]),
			offsets: offs
		};
		configs.set(skin, config);
		return config;
	}

	function loadAnims(skin:String, assetModifier:String = 'base', ?animName:String = null):NoteSplashConfig {
		maxAnims = 0;
		if(skin != '') 
			frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(skin, assetModifier, 'default', 'noteskins/notes'));
		else
			frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset('noteSplashes', assetModifier, 'default', 'noteskins/notes'));
		
		var config:NoteSplashConfig = null;
		config = precacheConfig(skin, assetModifier);
		if(animName == null)
			animName = config != null ? config.anim : 'note splash';

		while(true) {
			var animID:Int = maxAnims + 1;
			for (i in 0...colArray.length) {
				if (!addAnimAndCheck('note$i-$animID', '$animName ${colArray[i]} $animID', 24, false)) {
					return config;
				}
			}
			maxAnims++;
		}
	}

	function addAnimAndCheck(name:String, anim:String, ?framerate:Int = 24, ?loop:Bool = false)
	{
		animation.addByPrefix(name, anim, framerate, loop);
		return animation.getByName(name) != null;
	}


	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// kill the note splash if it's done
		if (animation.finished)
		{
			// set the splash to invisible
			if (visible)
				visible = false;
		}
		//
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		// make sure the animation is visible
		if (!Init.trueSettings.get('Disable Note Splashes'))
			visible = true;

		super.playAnim(AnimName, Force, Reversed, Frame);
	}
}
