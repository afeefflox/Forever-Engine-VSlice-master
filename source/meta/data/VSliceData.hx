package meta.data;

typedef VSliceChart =
{
	var scrollSpeed:Dynamic;	// Map<String, Float>
	var events:Array<VSliceEvent>;
	var notes:Dynamic;			// Map<String, Array<VSliceNote>>
	var generatedBy:String;
	var version:String;
}

typedef VSliceNote =
{
	var t:Float;					// Strum time
	var d:Int;						// Note data
	@:optional var l:Null<Float>;	// Sustain Length
	@:optional var k:String;		// Note type
}

typedef VSliceEvent =
{
	var t:Float;	//Strum time
	var e:String;	//Event name
	var v:Dynamic;	//Values
}

// Metadata
typedef VSliceMetadata = 
{
	var songName:String;
	var artist:String;
	var charter:String;
	var playData:VSlicePlayData;

	var timeFormat:String;
	var timeChanges:Array<VSliceTimeChange>;
	var generatedBy:String;
	var version:String;
}

typedef VSlicePlayData =
{
	var difficulties:Array<String>;
	var characters:VSliceCharacters;
	var songVariations:Array<String>;
	var noteStyle:String;
	var stage:String;
}

typedef VSliceCharacters =
{
	var player:String;
	var girlfriend:String;
	var opponent:String;
}

typedef VSliceTimeChange =
{
	var t:Float; //Time Stamp
	var bpm:Float;
}

typedef PsychEventChart = {
	var events:Array<Dynamic>;
	var format:String;
}

// Package
typedef VSlicePackage =
{
	var chart:VSliceChart;
	var metadata:VSliceMetadata;
}

typedef PsychPackage =
{
	var difficulties:Map<String, SwagSong>;
	var events:PsychEventChart;
}

class VSliceData {
	public static final metadataVersion = '2.2.3';
	public static final chartVersion = '2.0.0';

	public static function export(songData:SwagSong):VSlicePackage
	{
		var events:Array<VSliceEvent> = [];
		var notes:Array<VSliceNote> = [];
		var generatedBy:String = 'Psych Engine v0.7.3 - Chart Editor V-Slice Exporter';
		var timeChanges:Array<VSliceTimeChange> = [];

		

		timeChanges.push({t: 0, bpm: songData.bpm});

		if(songData.notes != null)
		{
			for (section in songData.notes)
			{
				if(section.sectionEvents != null && section.sectionEvents.length > 0)
				{
					for (songEvents in section.sectionEvents) 
					{
						switch(songEvents.name) //Convert Event Stuff (cuz I worte diffrent :/)
						{
							case 'Focus Camera':
								var values:Array<String> = songEvents.values[0].split(',');
							    var posY:Null<Float> = Std.parseFloat(values[0]);
							    var posX:Null<Float> = Std.parseFloat(values[1]);
							    if(Math.isNaN(posY)) posY = 0;
							    if(Math.isNaN(posX)) posX = 0;

							    var target:Int = 0;
							    switch(songEvents.values[1].toLowerCase()) 
							    {
								    case 'boyfriend':
									    target = 0;
								    case 'dad':
									    target = 1;
								    case 'gf':
									    target = 2;
							    }
								events.push({t: songEvents.time, e: 'FocusCamera',  
								    v: {
									    duration: (songEvents.values[3] == 0 || songEvents.values[3] == 1) ? 1 : songEvents.values[3], 
									    x: posX,
									    y: posY,
									    ease: songEvents.values[2].toUpperCase(),
									    char: target
								    }
							    }); 
							case 'Play Animation':
								events.push({t: songEvents.time, e: 'PlayAnimation',  
								    v: {
									    force: songEvents.values[2],
									    anim: songEvents.values[1], 
									    target: songEvents.values[0]
								    }
						        });
							default:
						        events.push({t: songEvents.time, e: songEvents.name, v: songEvents.values}); 
						}
					}
				}

				if(section.sectionNotes != null && section.sectionNotes.length > 0)
				{
					for (note in section.sectionNotes)
					{
						//Do FNF Leagcy Chart 
						if (note.data < 0) continue;

						if (note.data > (4 * 2)) note.data = note.data % (2 * 4);

						if (!section.mustHitSection)
						{
							if (note.data >= 4)
								note.data -= 4;
							else
								note.data += 4;
						}
						
						var vsliceNote:VSliceNote = {t: note.time, d: note.data};
						if(note.length > 0)
							vsliceNote.l = note.length;
						if(note.kind != null && note.kind.length > 0)
						{
							switch(note.kind) 
							{
								case "0":
									vsliceNote.k = "normal";
								default:
									vsliceNote.k =  (note.kind.startsWith('default')) ? note.kind.replace('default', '').replace('-','') : note.kind;
							}
						}
							
						notes.push(vsliceNote);
					}
				}

				if (section.changeBPM ?? false)
				{
					var firstNote = section.sectionNotes[0];
					if (firstNote != null) timeChanges.push({t: firstNote.time, bpm: section.bpm});
				}

				var lastSectionWasMustHit:Null<Bool> = null;

				if (section.mustHitSection != lastSectionWasMustHit)
				{
					lastSectionWasMustHit = section.mustHitSection;
					var firstNote = section.sectionNotes[0];
					if (firstNote != null) events.push({t: firstNote.time, e: 'FocusCamera', v: {char: section.mustHitSection ? 0 : 1}}); 
				}
			}
		}

		var composer:String = 'Unknown';
		if(Reflect.hasField(songData, 'artist')) composer = Reflect.field(songData, 'artist');
		else if(Reflect.hasField(songData, 'composer')) composer = Reflect.field(songData, 'composer');
		
		var charter:String = 'Unknown';
		if(Reflect.hasField(songData, 'charter')) composer = Reflect.field(songData, 'charter');
		
		var scrollSpeed:Map<String, Float> = [];
		var notesMap:Map<String, Array<VSliceNote>> = [];

		//One Difficulty is enough I guess

		scrollSpeed.set(PlayState.curDifficulty, songData.speed);
		notesMap.set(PlayState.curDifficulty, notes);

		var chart:VSliceChart = {
			scrollSpeed: scrollSpeed,
			events: events,
			notes: notesMap,
			generatedBy: generatedBy,
			version: chartVersion //idk what "version" does on V-Slice, but it seems to break without it
		};

		var variation:Array<String> = [];

		if(songData.variation != null && songData.variation != "")
			variation.push(songData.variation);

		var metadata:VSliceMetadata = {
			songName: songData.song,
			artist: composer,
			charter: charter,
			playData: {
				difficulties: [PlayState.curDifficulty],
				characters: {
					player: songData.characters[0],
					girlfriend: songData.characters[2] != null ? songData.characters[2] : null,
					opponent: songData.characters[1],
				},
				songVariations: variation,
				noteStyle: (songData.assetModifier != 'pixel') ? 'funkin' : 'pixel',
				stage: songData.stage
			},
			timeFormat: 'ms',
			timeChanges: timeChanges,
			generatedBy: generatedBy,
			version: metadataVersion //idk what "version" does on V-Slice, but it seems to break without it
		};
		return {chart: chart, metadata: metadata};
	}
}