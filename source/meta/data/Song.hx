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


typedef SongMeta = {
	var events:Array<SwagSection>;
	var diffs:Array<String>;

}

typedef SwagSection =
{
	var ?sectionNotes:Array<Array<Dynamic>>;
    var ?sectionEvents:Array<Array<Dynamic>>;
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
		arrowSkin: "",
		splashSkin: "noteSplashes", //fuck you psych
		validScore: true,
		variation: ""
	};

    public static var DEFAULT_SECTION:SwagSection = {
		sectionNotes: [],
        sectionEvents: [],
        sectionBeats: 4,
        mustHitSection: true,
        bpm: 0,
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
		song = JsonUtil.checkJson(DEFAULT_SONG, song);

        var specialFields:Array<Array<Dynamic>> = [
			['characters', ['bf','dad','gf']]
		];
		
		for (field in specialFields) {
			if (!Reflect.hasField(song, field[0])) {
				Reflect.setField(song, field[0], field[1]);
			}
		}

		for (field in Reflect.fields(song)) {
			switch (field) {
				case 'gfVersion' | 'gf' | 'player3' | 'player2' | 'player1':
					final playerIndex:Int = switch(field) {
						case 'player1': 0;
						case 'player2': 1;
						default:		2;
					}
					final players:Array<String> = Reflect.field(song, 'characters');
					players[playerIndex] = Reflect.field(song, field);
					Reflect.setField(song, 'characters', players);
					Reflect.deleteField(song, field);
				case 'events':
					final isFps = Reflect.hasField(Reflect.field(song, "events"), "events");
					song = isFps ? convertFpsChart(song) : convertPsychChart(song);
					Reflect.deleteField(song, field);
			}
		}
		
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
				if (n[1] > STRUMS_LENGTH - 1) { // Convert extra key charts to 4 key
					if (n[3] == null) n.push("default-extra");
					else if (n[3] == 0) n[3] = "default-extra";
				}
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
					if (type == "default" || type == "0") note = note.pop(); 
				}
				sec.sectionNotes.sort(sortNotes);
			}
			if (sec.sectionEvents.length <= 0 || metaClear)
				Reflect.deleteField(sec, 'sectionEvents');

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

    public static function convertFpsChart(song:SwagSong) {
		final fpsEvents:Array<Dynamic> = Reflect.field(Reflect.field(song, "events"), "events");
		if (fpsEvents == null || fpsEvents.length <= 0) return song;

		final events:Map<Int, Array<Array<Dynamic>>> = [];
		for (e in fpsEvents) {
			if (!events.exists(e[0])) events.set(e[0], []);
			events.get(e[0]).push([e[1], e[3], []]);
		}

		for (i in events.keys()) {
			checkAddSections(song, i);
			song.notes[i] = checkSection(song.notes[i]);
			for (e in events.get(i))
				song.notes[i].sectionEvents.push(e);
		}

		return song;
	}
	
	// Converts psych and forever engine events
	public static function convertPsychChart(song:SwagSong):SwagSong {
		final psychEvents:Array<Dynamic> = Reflect.field(song, 'events');
		if (psychEvents == null || psychEvents.length <= 0) return song;

		final events:Array<Array<Dynamic>> = [];
		for (e in psychEvents) {
			final eventTime = e[0];
			final _events:Array<Array<Dynamic>> = e[1];
			for (i in _events) events.push([eventTime, i[0], [i[1], i[2]]]);
		}

		for (i in events) {
			final eventSec = getTimeSection(song, i[0]);
			checkAddSections(song, eventSec);
			song.notes[eventSec] = checkSection(song.notes[eventSec]);
			song.notes[eventSec].sectionEvents.push(i);
		}

		return song;
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