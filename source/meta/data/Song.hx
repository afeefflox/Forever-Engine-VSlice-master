package meta.data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import sys.io.File;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var characters:Array<String>;
	var stage:String;
	var assetModifier:String;
	var arrowSkin:String;
	var splashSkin:String;
	var validScore:Bool;
	var variation:String;
}


typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
}

typedef SwagEvent = 
{
	var strumTime:Float;
	var name:String;
	var values:Array<String>;
}


class Song implements IPlayStateScriptedClass
{
	public var id:String;
	public var data:SwagSong;
	public function new(id:String)
	{
		this.id = id;
	}

	public static var DEFAULT_SONG:SwagSong = {
		song: "test",
		notes: [],
		events: [],
		bpm: 150,
		needsVoices: true,
		speed: 1,
		characters: ["bf", "dad", "gf"],
		stage: "stage",
		assetModifier: "base",
		arrowSkin: "",
		splashSkin: "",
		validScore: true,
		variation: ""
	};
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Assets.getText(Paths.songJson(folder.toLowerCase(), jsonInput.toLowerCase())).trim();

		while (!rawJson.endsWith("}"))
			rawJson = rawJson.substr(0, rawJson.length - 1);

		var songJson:Dynamic = parseJSONshit(rawJson);
		onLoadJson(songJson);
		return songJson;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		return swagShit;
	}

	private static function onLoadJson(data:Dynamic)
	{
		data.validScore = true;
		if(data.characters == null)
		{
			data.characters = [data.player1, data.player2, data.gfVersion];
			data.player1 = data.player2 = data.gfVersion = null; //heh kill it
		}

		if(data.variation == null)
			data.variation = ""; //for erect :/

		if(data.events == null)
			data.events = [];
	}

	public function toString():String
	{
		return 'Song($id)';
	}

	public function onPause(event:PauseScriptEvent):Void {};
	public function onResume(event:ScriptEvent):Void {};
	public function onSongStart(event:ScriptEvent):Void {};
	public function onSongEnd(event:ScriptEvent):Void {};
	public function onGameOver(event:ScriptEvent):Void {};
	public function onSongRetry(event:ScriptEvent):Void {};
	public function onNoteIncoming(event:NoteScriptEvent) {}
	public function onNoteHit(event:HitNoteScriptEvent) {}
	public function onNoteMiss(event:NoteScriptEvent):Void {};
	public function onNoteGhostMiss(event:GhostMissNoteScriptEvent):Void {};
	public function onStepHit(event:SongTimeScriptEvent):Void {};
	public function onBeatHit(event:SongTimeScriptEvent):Void {};
	public function onCountdownStart(event:CountdownScriptEvent):Void {};
	public function onCountdownStep(event:CountdownScriptEvent):Void {};
	public function onCountdownEnd(event:CountdownScriptEvent):Void {};
	public function onScriptEvent(event:ScriptEvent):Void {};
	public function onCreate(event:ScriptEvent):Void {};
	public function onDestroy(event:ScriptEvent):Void {};  
	public function onUpdate(event:UpdateScriptEvent):Void {};
}
