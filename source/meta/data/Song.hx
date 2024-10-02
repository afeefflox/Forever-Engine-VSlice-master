package meta.data;

import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import sys.io.File;

using StringTools;

abstract NoteJson(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic>
{
	public var time(get, set):Float;
	inline function set_time(value):Float return this[0] = value;
	inline function get_time():Float return this[0];

	public var data(get, set):Int;
	inline function set_data(value):Int return this[1] = value;
	inline function get_data():Int return this[1];

	public var length(get, set):Float;
	inline function set_length(value):Float return this[2] = value;
	inline function get_length():Float return this[2] ?? 0;

	public var kind(get, set):String;
	inline function set_kind(value):String return this[3] = value;
	inline function get_kind():String return this[3];

	public inline function push(value:Dynamic) this.push(value);
	public inline function pop() return this.pop();
	public inline function getDirection(strumlineSize:Int = 4):Int   return Std.int(this[1]) % strumlineSize;
}

abstract EventJson(Array<Dynamic>) from Array<Dynamic> to Array<Dynamic> {
	public var time(get, set):Float;
	inline function set_time(value):Float return this[0] = value;
	inline function get_time():Float return this[0];

	public var name(get, set):String;
	inline function set_name(value):String return this[1] = value;
	inline function get_name():String return this[1];

	public var values(get, set):Array<Dynamic>;
	inline function set_values(value):Array<Dynamic> return this[2] = value;
	inline function get_values():Array<Dynamic> return this[2];

	public inline function push(value:Dynamic) this.push(value);
	public inline function pop() return this.pop();
}

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;

	var characters:Array<String>;
	var stage:String;
	var assetModifier:String;
	var validScore:Bool;
	var variation:String;
}


typedef SongMeta = {
	var events:Array<SwagSection>;
	var diffs:Array<String>;

}

typedef SwagSection =
{
	var ?sectionNotes:Array<NoteJson>;
	var ?sectionEvents:Array<EventJson>;
	var ?sectionBeats:Float;
	var ?mustHitSection:Bool;
	var ?bpm:Float;
	var ?changeBPM:Bool;
}

typedef SwagEvent = 
{
	var strumTime:Float;
	var name:String;
	var values:Array<Dynamic>;
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
		bpm: 150,
		needsVoices: true,
		speed: 1,
		characters: ["bf", "dad", "gf"],
		stage: "stage",
		assetModifier: "base",
		validScore: true,
		variation: ""
	};

    public static var DEFAULT_SECTION:SwagSection = {
		sectionNotes: [],
        sectionEvents: [],
        sectionBeats: 4,
        mustHitSection: true,
        bpm: 150,
        changeBPM: false
	};

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson = Paths.charts(folder, jsonInput);
        var meta = getSongMeta(folder);
		if (meta != null) meta = meta.diffs.contains(jsonInput) ? meta : null; // Only use if diff is included

        if (Paths.exists(rawJson, TEXT)) 
            return checkSong(parseJson(rawJson), meta);		
        trace('$folder-$jsonInput CHART NOT FOUND');
		if (folder == "tutorial" && jsonInput == "hard") throw 'Failed to load chart'; // Couldnt even find tutorial
		else return loadFromJson('hard','tutorial');
	}

    inline public static function getSongMeta(song:String):Null<SongMeta> {
		var meta = Paths.getFileContent(Paths.charts(song, 'songMeta'));
		return meta.length > 0 ? cast Json.parse(meta) : null;
	}

    public static function checkSong(?song:SwagSong, ?meta:SongMeta):SwagSong {
		song = FunkinFormat.songCheck(song);

		song = JsonUtil.checkJson(DEFAULT_SONG, song);

		if (song.notes.length <= 0) song.notes.push(DEFAULT_SECTION);
		for (i in song.notes) {
			i = checkSection(i);
			if (i.sectionNotes.length > 100) return DEFAULT_SONG; // Fuck off
		}

        if (meta != null) { // Apply song metaData
			for (s in 0...meta.events.length) {
				if (!Reflect.hasField(meta.events[s], "sectionEvents")) continue;
				for (i in meta.events[s].sectionEvents.copy())
					song.notes[s].sectionEvents.push(i);
			}
		}

		return song;
	}

    public static function checkSection(?section:SwagSection):SwagSection {
		section = JsonUtil.checkJson(DEFAULT_SECTION, section);
		final foundNotes:Map<String, Bool> = [];
		final uniqueNotes:Array<Array<Dynamic>> = []; // Skip duplicate notes
		for (i in section.sectionNotes) {
			final key = '${Math.floor(i[0])}-${i[1]}-${i[3]}';
			if (!foundNotes.exists(key)) {
				foundNotes.set(key, true);
				uniqueNotes.push(i);
			}
		}
		section.sectionNotes = uniqueNotes;
		for (n in section.sectionNotes) {
			if (n[1] < 0) {
				section.sectionEvents.push([n[0], n[2], [n[3], n[4]]]);
				section.sectionNotes.remove(n);
			} else {
                var STRUMS_LENGTH = 4 * 2;
				if (n[3] == null) n.push("default");
				else if (n[3] == 0) n[3] = "default";
				n[1] %= STRUMS_LENGTH;
			}
		}
		foundNotes.clear();
		return section;
    }

	public static function getSectionTime(song:SwagSong, section:Int = 0):Float {
		var BPM:Float = song.bpm;
        var time:Float = 0;
        for (i in 0...section) {
			checkAddSections(song, i);
			if (song.notes[i].changeBPM) BPM = song.notes[i].bpm;
			time += 4 * (60000 / BPM);
        }
        return time;
	}

	inline public static function checkAddSections(song:SwagSong, index:Int, i:Int = 0) {
		while (song.notes.length < index + 1)
			song.notes.push(DEFAULT_SECTION);

		while (i < index) {
			if (song.notes[i] == null) song.notes[i] = DEFAULT_SECTION;
			i++;
		}
	}

	public static function getTimeSection(song:SwagSong, time:Float):Int {
		var section:Int = 0;
		var startTime:Float = 0;
		var endTime:Float = getSectionTime(song, 1);
		while (!(time >= startTime && time < endTime)) {
			section++;
			startTime = Reflect.copy(endTime);
			endTime = getSectionTime(song, section+1);
		}
		return section;
	}

    public static function optimizeJson(input:SwagSong, metaClear:Bool = false):SwagSong {
		var song:SwagSong = JsonUtil.copyJson(input);
		for (sec in song.notes) {
			if (!sec.changeBPM) {
				Reflect.deleteField(sec, 'changeBPM');
				Reflect.deleteField(sec, 'bpm');
			}
			if (sec.sectionNotes.length <= 0) {
				Reflect.deleteField(sec, 'sectionNotes');
			} else {
				for (note in sec.sectionNotes) {
					if (note[3] == null) continue;
					final type:String = note[3]; // hl is gay
					if (type == "default") note = note.pop(); 
				}
				sec.sectionNotes.sort(sortNotes);
			}
			if (sec.sectionEvents.length <= 0 || metaClear)
				Reflect.deleteField(sec, 'sectionEvents');

			if(sec.sectionBeats == 4)
				Reflect.deleteField(sec, 'sectionBeats');

			if (sec.mustHitSection)
				Reflect.deleteField(sec, 'mustHitSection');
		}
		if (song.notes.length > 1) {
			while (true) {
				final lastSec = song.notes[song.notes.length-1];
				if (lastSec == null) break;
				if (Reflect.fields(lastSec).length <= 0) 	song.notes.pop();
				else 										break;
			}
		}
		return song;
	}

	private static function sortNotes(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int {
		return FlxSort.byValues(FlxSort.ASCENDING,  Obj1[0], Obj2[0]);
	}

    inline public static function parseJson(chartPath:String, ?rawJson:String):SwagSong {
		if (rawJson == null) {
			rawJson = Paths.getFileContent(chartPath).trim();
			while (!rawJson.endsWith("}"))	rawJson = rawJson.substr(0, rawJson.length - 1);
		}
		final swagShit:SwagSong = Json.parse(rawJson).song;
		return swagShit;
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
	public function onSongEvent(event:SongEventScriptEvent):Void {};
}