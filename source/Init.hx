import flixel.FlxG;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import meta.CoolUtil;
import meta.Overlay;
import meta.data.Highscore;
#if discord_rpc
import meta.data.dependency.Discord;
#end
import meta.state.*;
import meta.state.charting.*;
import openfl.Assets;
using StringTools;

/** 
	Enumerator for settingtypes

	[08/19/2023 - by: crowplexus]
	this was a normal enum beforehand, it was converted
	to an abstract so HashLink could work
**/
enum abstract SettingTypes(Int) to Int
{
	var Checkmark = 0;
	var Selector = 1;
}

/**
	This is the initialisation class. if you ever want to set anything before the game starts or call anything then this is probably your best bet.
	A lot of this code is just going to be similar to the flixel templates' colorblind filters because I wanted to add support for those as I'll
	most likely need them for skater, and I think it'd be neat if more mods were more accessible.
**/
class Init extends FlxState
{
	/*
		Okay so here we'll set custom settings. As opposed to the previous options menu, everything will be handled in here with no hassle.
		This will read what the second value of the key's array is, and then it will categorise it, telling the game which option to set it to.

		0 - boolean, true or false checkmark
		1 - choose string
		2 - choose number (for fps so its low capped at 30)
		3 - offsets, this is unused but it'd bug me if it were set to 0
		might redo offset code since I didnt make it and it bugs me that it's hardcoded the the last part of the controls menu
	 */
	public static var FORCED = 'forced';
	public static var NOT_FORCED = 'not forced';

	public static var gameSettings:Map<String, Dynamic> = [
		'Downscroll' => [
			false,
			Checkmark,
			'Whether to have the strumline vertically flipped in gameplay.',
			NOT_FORCED
		],
		'Controller Mode' => [
			false,
			Checkmark,
			'Whether to use a controller instead of the keyboard to play.',
			NOT_FORCED
		],
		'Auto Pause' => [
			true,
			Checkmark,
			'Whether to pause the game automatically if the window is unfocused.',
			NOT_FORCED
		],
		'FPS Counter' => [true, Checkmark, 'Whether to display the FPS counter.', NOT_FORCED],
		'Memory Counter' => [
			true,
			Checkmark,
			'Whether to display approximately how much memory is being used.',
			NOT_FORCED
		],
		'Debug Info' => [
			false,
			Checkmark,
			'Whether to display information like your game state.',
			NOT_FORCED
		],
		'Reduced Movements' => [
			false,
			Checkmark,
			'Whether to reduce movements, like icons bouncing or beat zooms in gameplay.',
			NOT_FORCED
		],
		'Stage Opacity' => [
			Checkmark,
			Selector,
			'Darkens non-ui elements, useful if you find the characters and backgrounds distracting.',
			NOT_FORCED
		],
		'Counter' => [
			'None',
			Selector,
			'Choose whether you want somewhere to display your judgements, and where you want it.',
			NOT_FORCED,
			['None', 'Left', 'Right']
		],
		'Display Accuracy' => [true, Checkmark, 'Whether to display your accuracy on screen.', NOT_FORCED],
		'Disable Antialiasing' => [
			false,
			Checkmark,
			'Whether to disable Anti-aliasing. Helps improve performance in FPS.',
			NOT_FORCED
		],
		// custom ones lol
		'Offset' => [Checkmark, 3],
		"Clip Style" => [
			'stepmania',
			Selector,
			"Chooses a style for hold note clippings; StepMania: Holds under Receptors; FNF: Holds over receptors",
			NOT_FORCED,
			['StepMania', 'FNF']
		],
		"Input System" => [
			'forever',
			Selector,
			"Chooses a Input System that make you easy it; V-Slice: it won't allow to do anti mash; Forever: it pretty much normal Psych Input",
			NOT_FORCED,
			['V-slice', 'Forever']
		],
		"Framerate Cap" => [120, Selector, 'Define your maximum FPS.', NOT_FORCED, ['']],
		"Opaque Arrows" => [
			false,
			Checkmark,
			"Makes the arrows at the top of the screen opaque again.",
			NOT_FORCED
		],
		"Opaque Holds" => [false, Checkmark, "Huh, why isnt the trail cut off?", NOT_FORCED],
		'Ghost Tapping' => [
			false,
			Checkmark,
			"Enables Ghost Tapping, allowing you to press inputs without missing.",
			NOT_FORCED
		],
		'Centered Notefield' => [false, Checkmark, "Center the notes and hide opponent notes"],
		"Custom Titlescreen" => [
			false,
			Checkmark,
			"Enables the custom Forever Engine titlescreen! (only effective with a restart)",
			FORCED
		],
		'Skip Text' => [
			'freeplay only',
			Selector,
			'Decides whether to skip cutscenes and dialogue in gameplay. May be always, only in freeplay, or never.',
			NOT_FORCED,
			['never', 'freeplay only', 'always']
		],
		'Skip Result' => [
			'never',
			Selector,
			'Decides whether to skip result screen. May be always, only in freeplay, or never.',
			NOT_FORCED,
			['never', 'freeplay only', 'story only', 'always']
		],
		'Fixed Judgements' => [
			false,
			Checkmark,
			"Fixes the judgements to the camera instead of to the world itself, making them easier to read.",
			NOT_FORCED
		],
		'Simply Judgements' => [
			false,
			Checkmark,
			"Simplifies the judgement animations, displaying only one judgement / rating sprite at a time.",
			NOT_FORCED
		],
		'Playable Character' => [
			['bf']
		],
		'Resolution' => [
			'1280x720',
			Selector,
			'pick resolution that your pc fit in that it',
			NOT_FORCED,
			['256x144', '544x416', '640x360', '854x480', '960x540', '1024x576', '1280x720', 'native']
		],
		'Enabled Mods' => [
			[]
		],
		'Input Offset' => [0, Selector, 'Define your maximum FPS.', NOT_FORCED, ['']],
		'Audio Visual Offset' => [0, Selector, 'Define your maximum FPS.', NOT_FORCED, ['']],
	];

	public static var trueSettings:Map<String, Dynamic> = [];
	public static var settingsDescriptions:Map<String, String> = [];
	public static var gameControls:Map<String, Dynamic> = [
		'UP' => [[FlxKey.UP, W], 2],
		'DOWN' => [[FlxKey.DOWN, S], 1],
		'LEFT' => [[FlxKey.LEFT, A], 0],
		'RIGHT' => [[FlxKey.RIGHT, D], 3],
		'ACCEPT' => [[FlxKey.SPACE, Z, FlxKey.ENTER], 4],
		'BACK' => [[FlxKey.BACKSPACE, X, FlxKey.ESCAPE], 5],
		'PAUSE' => [[FlxKey.ENTER, P], 6],
		'RESET' => [[R, null], 13],
		'UI_UP' => [[FlxKey.UP, W], 8],
		'UI_DOWN' => [[FlxKey.DOWN, S], 9],
		'UI_LEFT' => [[FlxKey.LEFT, A], 10],
		'UI_RIGHT' => [[FlxKey.RIGHT, D], 11],
		'VOLUME_MUTE' => [[FlxKey.ZERO, NONE], 12],
		'VOLUME_DOWN' => [[FlxKey.NUMPADMINUS, MINUS], 13],
		'VOLUME_UP' => [[FlxKey.NUMPADPLUS, PLUS], 14],
		'FREEPLAY_LEFT' => [[Q, null], 15],
		'FREEPLAY_RIGHT' => [[E, null], 16],
	];

	override public function create():Void
	{
		FlxSprite.defaultAntialiasing = !Init.trueSettings.get('Disable Antialiasing');
		FlxG.game.focusLostFramerate = 30;

		#if discord_rpc
		Discord.initializeRPC();

		lime.app.Application.current.onExit.add(function(exitCode) {
			Discord.shutdownRPC();
		});
		#end

		FlxG.save.bind('options', CoolUtil.getSavePath());
		PlayerSettings.init();
		loadSettings();
		loadControls();

		CommandDebug.initialize();
		EvacuateDebug.initialize();
		ReloadAssetsDebug.initialize();
		
		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		#end
		
		trace('Parsing game data...');
		var perfStart:Float = TimerUtil.start();

		//BaseRegistry
		SongRegistry.instance.loadEntries();
		LevelRegistry.instance.loadEntries();
		NoteStyleRegistry.instance.loadEntries();
		PlayerRegistry.instance.loadEntries();
		StageRegistry.instance.loadEntries();
		AlbumRegistry.instance.loadEntries();
		FreeplayStyleRegistry.instance.loadEntries();

		//Non BaseRegistry
		SongEventRegistry.loadEventCache();
		NoteKindManager.loadScripts();
		CharacterRegistry.loadCharacterCache();

		ModuleHandler.buildModuleCallbacks();
		ModuleHandler.loadModuleCache();
		ModuleHandler.callOnCreate();

		for (id in DataAssets.listDataFilesInPath('songs', '.ogg', SOUND)) //Percache Song (Inst and Voices)
		{
			FlxG.sound.cache(id);
		}
		trace('Parsing game data took: ${TimerUtil.ms(perfStart)}');


		// Some additional changes to default HaxeFlixel settings, both for ease of debugging and usability.
		FlxG.fixedTimestep = false; // This ensures that the game is not tied to the FPS
		FlxG.mouse.useSystemCursor = true; // Use system cursor because it's prettier
		FlxG.mouse.visible = false; // Hide mouse on start
		//FlxGraphic.defaultPersist = true; // make sure we control all of the memory

		FlxG.switchState(Type.createInstance(Main.initialState, []));
	}

	public static function loadSettings():Void
	{
		// set the true settings array
		// only the first variable will be saved! the rest are for the menu stuffs

		// IF YOU WANT TO SAVE MORE THAN ONE VALUE MAKE YOUR VALUE AN ARRAY INSTEAD
		for (setting in gameSettings.keys())
			trueSettings.set(setting, gameSettings.get(setting)[0]);

		// NEW SYSTEM, INSTEAD OF REPLACING THE WHOLE THING I REPLACE EXISTING KEYS
		// THAT WAY IT DOESNT HAVE TO BE DELETED IF THERE ARE SETTINGS CHANGES
		if (FlxG.save.data.settings != null)
		{
			var settingsMap:Map<String, Dynamic> = FlxG.save.data.settings;
			for (singularSetting in settingsMap.keys())
				if (gameSettings.get(singularSetting) != null && gameSettings.get(singularSetting)[3] != FORCED)
					trueSettings.set(singularSetting, FlxG.save.data.settings.get(singularSetting));
		}

		// lemme fix that for you
		if (!Std.isOfType(trueSettings.get("Framerate Cap"), Int)
			|| trueSettings.get("Framerate Cap") < 30
			|| trueSettings.get("Framerate Cap") > 360)
			trueSettings.set("Framerate Cap", 30);

		if (!Std.isOfType(trueSettings.get("Stage Opacity"), Int)
			|| trueSettings.get("Stage Opacity") < 0
			|| trueSettings.get("Stage Opacity") > 100)
			trueSettings.set("Stage Opacity", 100);

		saveSettings();

		updateAll();

		if (FlxG.save.data.volume != null)
			FlxG.sound.volume = FlxG.save.data.volume;
		if (FlxG.save.data.mute != null)
			FlxG.sound.muted = FlxG.save.data.mute;
	}

	public static function loadControls():Void
	{
		if ((FlxG.save.data.gameControls != null) && (Lambda.count(FlxG.save.data.gameControls) == Lambda.count(gameControls)))
			gameControls = FlxG.save.data.gameControls;

		saveControls();
	}

	public static function saveSettings():Void
	{
		// ez save lol
		FlxG.save.data.settings = trueSettings;
		FlxG.save.flush();

		updateAll();
	}
	
	public static function saveControls():Void
	{
		FlxG.save.data.gameControls = gameControls;
		FlxG.save.flush();
	}

	public static function updateAll()
	{
		FlxG.autoPause = trueSettings.get('Auto Pause');

		trace('Enabled Mods: ${trueSettings.get('Enabled Mods')}');

		PolymodHandler.initialize();

		FlxSprite.defaultAntialiasing = !Init.trueSettings.get('Disable Antialiasing');

		Overlay.updateDisplayInfo(trueSettings.get('FPS Counter'), trueSettings.get('Debug Info'), trueSettings.get('Memory Counter'));

		#if !html5
		Main.updateFramerate(trueSettings.get("Framerate Cap"));
		Main.resizeGame(trueSettings.get("Resolution"));
		#end
	}

	public static function reloadVolumeKeys()
	{
		Main.muteKeys = copyKey(gameControls.get('VOLUME_MUTE')[0]);
		Main.volumeDownKeys = copyKey(gameControls.get('VOLUME_DOWN')[0]);
		Main.volumeUpKeys = copyKey(gameControls.get('VOLUME_UP')[0]);
		toggleVolumeKeys(true);
	}

	public static function toggleVolumeKeys(?turnOn:Bool = true)
	{
		FlxG.sound.muteKeys = turnOn ? Main.muteKeys : [];
		FlxG.sound.volumeDownKeys = turnOn ? Main.volumeDownKeys : [];
		FlxG.sound.volumeUpKeys = turnOn ? Main.volumeUpKeys : [];
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}
}
