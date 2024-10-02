package meta.data;

class FunkinFormat
{
    public static function songCheck(?song:SwagSong):SwagSong
    {
        if (song == null)
			return song;

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
                case 'players': //Maru Chart :/
                    Reflect.setField(song, 'characters', field);
					Reflect.deleteField(song, field);
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
		return song;
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
			Song.checkAddSections(song, i);
			song.notes[i] = Song.checkSection(song.notes[i]);
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
			final eventSec = Song.getTimeSection(song, i[0]);
			Song.checkAddSections(song, eventSec);
			song.notes[eventSec] = Song.checkSection(song.notes[eventSec]);
			song.notes[eventSec].sectionEvents.push(i);
		}

		return song;
	}

    //Opps stolen from Maru Engine
    public static function convertVSliceSong(song:Dynamic, diff:String):SwagSong
	{
		for (note in cast(Reflect.field(song.notes, diff), Array<Dynamic>)) {
		
		}


		return song;
	}

	public static function convertVSliceMeta(meta:Dynamic, diff:String):SongMeta
	{
		return meta;
	}

}