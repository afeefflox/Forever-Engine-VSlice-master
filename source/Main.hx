package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxColor;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import haxe.io.Path;
import lime.app.Application;
import meta.*;
import meta.data.PlayerSettings;
import meta.data.dependency.Discord;
import meta.data.dependency.FNFTransition;
import openfl.Assets;
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.UncaughtErrorEvent;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import haxe.ui.Toolkit;
// Here we actually import the states and metadata, and just the metadata.
// It's nice to have modularity so that we don't have ALL elements loaded at the same time.
// at least that's how I think it works. I could be stupid!
class Main extends Sprite
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	
	// class action variables
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var initialState:Class<FlxState> = meta.state.TitleState; // Determine the state the game should begin at
	public static var framerate:Int = #if (html5 || neko) 60 #else 120 #end; // How many frames per second the game should run at.

	public static final gameVersion:String = '0.3.2h';

	// var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var infoCounter:Overlay; // initialize the heads up display that shows information before creating it.

	// most of these variables are just from the base game!
	// be sure to mess around with these if you'd like.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	// calls a function to set the game up
	public function new()
	{
		super();

		meta.modding.PolymodHandler.loadAllMods();

		if (stage != null)
			init();
		else
			addEventListener(Event.ADDED_TO_STAGE, init);
	}

	function init(?event:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
			removeEventListener(Event.ADDED_TO_STAGE, init);
		setupGame();
	}

	function setupGame():Void
	{
		initHaxeUI();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);

		var game:FlxGame = new FlxGame(gameWidth, gameHeight, Init, framerate, framerate, skipSplash);
		addChild(game);

		FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
			// Prevent Flixel from listening to key inputs when switching fullscreen mode
			// thanks nebulazorua @crowplexus
			if (e.keyCode == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();
		}, false, 100);

		// test initialising the player settings
		infoCounter = new Overlay(0, 0);
		addChild(infoCounter);
	}

	public static function framerateAdjust(input:Float)
	{
		return input * (60 / FlxG.drawFramerate);
	}

	/*  This is used to switch "rooms," to put it basically. Imagine you are in the main menu, and press the freeplay button.
		That would change the game's main class to freeplay, as it is the active class at the moment.
	 */
	public static function switchState(target:FlxState)
	{
		// Custom made Trans in
		if (!FlxTransitionableState.skipNextTransIn)
		{
			FlxG.state.openSubState(new FNFTransition(0.35, false));
			FNFTransition.finishCallback = function()
			{
				FlxG.switchState(target);
			};
			//trace('changed state');
		}
		else
			// load the state
			FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int)
	{
		// flixel will literally throw errors at me if I dont separate the orders
		if (newFramerate > FlxG.updateFramerate)
		{
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else
		{
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}

	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");

		path = 'crash/FE_$dateNow.txt';

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error;
		//errMsg += "\nPlease report this error to the GitHub page: https://github.com/CrowPlexus-FNF/Forever-Engine-Legacy";

		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println('Crash dump saved in ${Path.normalize(path)}');
		Sys.println("Making a simple alert...");

		#if windows
		var crashDialoguePath:String = "FE-CrashDialog.exe";
		if (FileSystem.exists(crashDialoguePath))
			new Process(crashDialoguePath, [path]);
		else
		#end
		Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}

	function initHaxeUI():Void
	{
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		Toolkit.autoScale = false;
		haxe.ui.focus.FocusManager.instance.autoFocus = false;
		Cursor.registerHaxeUICursors();
		haxe.ui.tooltips.ToolTipManager.defaultDelay = 200;
	}
}

class GlobalGraphic extends FlxGraphic {
	override function destroy() {} // Lol
}