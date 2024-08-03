package meta.data;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import gameObjects.userInterface.notes.*;
import meta.data.Song.SwagSection;
import meta.data.Song.SwagSong;
import meta.data.Song.SwagEvent;
import meta.state.PlayState;

class ChartLoader
{
	public static function generateChartType(songData:SwagSong):Dynamic
	{
		var unspawnNotes:Array<Note> = [];
		var noteData:Array<SwagSection>;
		for (section in songData.notes)
		{
			if(section.sectionNotes != null && section.sectionNotes.length > 0)
			{
				for (songNotes in section.sectionNotes)
				{
					var daStrumTime:Float = #if !neko songNotes[0] - Init.trueSettings['Offset'] /* - | late, + | early */ #else songNotes[0] #end;
					var daNoteData:Int = Std.int(songNotes[1] % 4);
					var gottaHitNote:Bool = section.mustHitSection;

					if (songNotes[1] > 3) gottaHitNote = !section.mustHitSection;
								
					var oldNote:Note = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					// create the new note
					var swagNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier, daStrumTime, daNoteData);
					swagNote.noteSpeed = songData.speed;
					swagNote.sustainLength = songNotes[2];
					swagNote.noteType = songNotes[3];
					swagNote.mustPress = gottaHitNote;
					swagNote.scrollFactor.set();
					unspawnNotes.push(swagNote);
	
					var susLength:Float = swagNote.sustainLength; 
					susLength = susLength / Conductor.stepCrochet;
		
					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote:Note = ForeverAssets.generateArrow(PlayState.assetModifier,
							daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, true, oldNote);
						sustainNote.scrollFactor.set();
						sustainNote.noteType = songNotes[3];
						sustainNote.mustPress = gottaHitNote;
						unspawnNotes.push(sustainNote);	
					}
				}
			}

			if(section.sectionEvents != null && section.sectionEvents.length > 0)
			{
				for (songEvents in section.sectionEvents)
				{
					var subEvent:SwagEvent = {
						strumTime: songEvents[0],
						name: songEvents[1],
						values: songEvents[2]
					};				
					if(EventsHandler.existsEvents(subEvent.name)) 
						EventsHandler.getEvents(subEvent.name).percacheFunction(subEvent.values);
					PlayState.instance.eventList.push(subEvent);

				}
			}
		}

		return unspawnNotes;
	}
}
