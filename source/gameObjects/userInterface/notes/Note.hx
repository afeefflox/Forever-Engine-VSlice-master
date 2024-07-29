package gameObjects.userInterface.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.*;
import meta.data.*;
import meta.data.dependency.FNFSprite;
import meta.state.PlayState;

typedef NoteSplashData = {
	disabled:Bool,
	texture:String,
	antialiasing:Bool,
	alpha:Float
}

class Note extends FNFSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var noteType(default, set):String = null;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;

	//Event
	public var eventName:String;
	public var eventVals:Array<String> = [];
	public var eventLength:Int = 0;

	// only useful for charting stuffs
	public var chartSustain:FlxSprite = null;
	public var rawNoteData:Int;

	// not set initially
	public var noteQuant:Int = -1;
	public var noteVisualOffset:Float = 0;
	public var noteSpeed:Float = 0;
	public var noteDirection:Float = 0;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	public static var swagWidth:Float = 160 * 0.7;

	// it has come to this.
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;
	public var texture(default, set):String = null;
	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var noteSplashData:NoteSplashData = {
		disabled: false,
		texture: null,
		antialiasing: true,
		alpha: (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.6
	};

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false)
	{
		super(x, y);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;

		// oh okay I know why this exists now
		y -= 2000;
		
		this.strumTime = strumTime;
		this.noteData = noteData;

		if(noteData > -1) {
			texture = '';

			if(!isSustainNote) 
				animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'Scroll');
		}

		// determine parent note
		if (isSustainNote && prevNote != null)
		{
			parentNote = prevNote;
			while (parentNote.parentNote != null)
				parentNote = parentNote.parentNote;
			parentNote.childrenNotes.push(this);
		}
		else if (!isSustainNote)
			parentNote = null;

		var changeableSkin:String = Init.trueSettings.get("Note Skin");
		if (isSustainNote && prevNote != null)
		{
			noteSpeed = prevNote.noteSpeed;

            if (changeableSkin.startsWith('quant')) 
                animation.play('holdend');
            else
                animation.play(UIStaticArrow.getColorFromNumber(noteData) + 'holdend');
                
			alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
				
			updateHitbox();
			if (prevNote.isSustainNote)
			{
                if (changeableSkin.startsWith('quant')) 
                {
                    prevNote.animation.play('hold');
                    prevNote.scale.y *= Conductor.stepCrochet / 100 * (43 / 52) * 1.5 * prevNote.noteSpeed;
                }
                else
                {
                    prevNote.animation.play(UIStaticArrow.getColorFromNumber(prevNote.noteData) + 'hold');
                    prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * prevNote.noteSpeed;
                }

				prevNote.updateHitbox();
			}

			// set note offset
			if (prevNote.isSustainNote)
				noteVisualOffset = prevNote.noteVisualOffset;
			else // calculate a new visual offset based on that note's width and newnote's width
				noteVisualOffset = ((prevNote.width * 0.5) - (width * 0.5));
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - (Timings.msThreshold) && strumTime < Conductor.songPosition + (Timings.msThreshold))
				canBeHit = true;
			else
				canBeHit = false;
		}
		else // make sure the note can't be hit if it's the dad's I guess
			canBeHit = false;

		if (tooLate || (parentNote != null && parentNote.tooLate))
			alpha = 0.3;
	}

	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote(PlayState.assetModifier, '', value);
		}
		texture = value;
		return value;
	}

	
	private function set_noteType(value:String):String {
		if(noteData > -1 && noteType != value) 
		{
			noteSplashData.texture = PlayState.SONG != null ? PlayState.SONG.splashSkin : 'noteSplashes';
			if (value != 'default' && value != null && value.length > 1) NoteTypeRegistry.instance.fetchEntry(value).initFunction(this);
			noteType = value;
		}
		return value;
	}

	public function reloadNote(assetModifier:String, ?prefix:String = '', ?texture:String = '', ?suffix:String = '') {
		if(prefix == null) prefix = '';
		if(texture == null) texture = '';
		if(suffix == null) suffix = '';

		var skin:String = texture;
		if(texture.length < 1) {
			skin = PlayState.SONG != null ? PlayState.SONG.arrowSkin : null;
			if(skin == null || skin.length < 1)
				skin = "NOTE_assets";
		}

		var animName:String = null;
		if(animation.curAnim != null) {
			animName = animation.curAnim.name;
		}
		var blahblah:String = prefix + skin + suffix;
		switch (assetModifier)
		{
			case 'pixel':
				if (isSustainNote)
					loadGraphic(Paths.image(ForeverTools.returnSkinAsset(blahblah + 'ENDS', assetModifier, Init.trueSettings.get("Note Skin"),'noteskins/notes')), true, 7,6);
				else
					loadGraphic(Paths.image(ForeverTools.returnSkinAsset(blahblah, assetModifier, Init.trueSettings.get("Note Skin"),'noteskins/notes')),true, 17, 17);

				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				loadPixelNoteAnims();
				antialiasing = false;
			default:
				frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(blahblah, assetModifier, Init.trueSettings.get("Note Skin"), 'noteskins/notes'));
				setGraphicSize(Std.int(width * 0.7));
				loadNoteAnims();
				antialiasing = true;
		}
		updateHitbox();
		if(animName != null) animation.play(animName, true);
	}

	function loadNoteAnims() {
		animation.addByPrefix('purpleholdend', 'pruple end hold', 24, true);
		animation.addByPrefix('greenholdend', 'green hold end', 24, true);
		animation.addByPrefix('redholdend', 'red hold end', 24, true);
		animation.addByPrefix('blueholdend', 'blue hold end', 24, true);
		
		animation.addByPrefix('purplehold', 'purple hold piece', 24, true);
		animation.addByPrefix('greenhold', 'green hold piece', 24, true);
		animation.addByPrefix('redhold', 'red hold piece', 24, true);
		animation.addByPrefix('bluehold', 'blue hold piece', 24, true);

		animation.addByPrefix('greenScroll', 'green0', 24, true);
		animation.addByPrefix('redScroll', 'red0', 24, true);
		animation.addByPrefix('blueScroll', 'blue0', 24, true);
		animation.addByPrefix('purpleScroll', 'purple0', 24, true);
	}

	function loadPixelNoteAnims() {
		if(isSustainNote)
		{
			animation.add('purpleholdend', [4], 24, true);
			animation.add('greenholdend', [6], 24, true);
			animation.add('redholdend', [7], 24, true);
			animation.add('blueholdend', [5], 24, true);

			animation.add('purplehold', [0], 24, true);
			animation.add('greenhold', [2], 24, true);
			animation.add('redhold', [3], 24, true);
			animation.add('bluehold', [1], 24, true);
		} 
		else
		{
			animation.add('greenScroll', [6], 24, true);
			animation.add('redScroll', [7], 24, true);
			animation.add('blueScroll', [5], 24, true);
			animation.add('purpleScroll', [4], 24, true);
		} 
	}

	/**
		Note creation scripts

		these are for all your custom note needs
	**/
	public static function returnDefaultNote(assetModifier, strumTime, noteData, noteType, ?isSustainNote:Bool = false, ?prevNote:Note = null):Note
	{
		var newNote:Note = new Note(strumTime, noteData, prevNote, isSustainNote);
		newNote.reloadNote(assetModifier, '', newNote.texture);
		return newNote;
	}

	public static function returnQuantNote(assetModifier, strumTime, noteData, noteType, ?isSustainNote:Bool = false, ?prevNote:Note = null):Note
	{
		var newNote:Note = new Note(strumTime, noteData, prevNote, isSustainNote);

		// actually determine the quant of the note
		if (newNote.noteQuant == -1)
		{
			/*
				I have to credit like 3 different people for these LOL they were a hassle
				but its gede pixl and scarlett, thank you SO MUCH for baring with me
			 */
			final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

			var curBPM:Float = Conductor.bpm;
			var newTime = strumTime;
			for (i in 0...Conductor.bpmChangeMap.length)
			{
				if (strumTime > Conductor.bpmChangeMap[i].songTime)
				{
					curBPM = Conductor.bpmChangeMap[i].bpm;
					newTime = strumTime - Conductor.bpmChangeMap[i].songTime;
				}
			}

			final beatTimeSeconds:Float = (60 / curBPM); // beat in seconds
			final beatTime:Float = beatTimeSeconds * 1000; // beat in milliseconds
			// assumed 4 beats per measure?
			final measureTime:Float = beatTime * 4;

			final smallestDeviation:Float = measureTime / quantArray[quantArray.length - 1];

			for (quant in 0...quantArray.length)
			{
				// please generate this ahead of time and put into array :)
				// I dont think I will im scared of those
				final quantTime = (measureTime / quantArray[quant]);
				if ((newTime #if !neko + Init.trueSettings['Offset'] #end + smallestDeviation) % quantTime < smallestDeviation * 2)
				{
					// here it is, the quant, finally!
					newNote.noteQuant = quant;
					break;
				}
			}
		}

		// note quants
		switch (assetModifier)
		{
			default:
				// inherit last quant if hold note
				if (isSustainNote && prevNote != null)
					newNote.noteQuant = prevNote.noteQuant;
				// base quant notes
				if (!isSustainNote)
				{
					// in case you're unfamiliar with these, they're ternary operators, I just dont wanna check for pixel notes using a separate statement
					var newNoteSize:Int = (assetModifier == 'pixel') ? 17 : 157;
					newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('NOTE_quants', assetModifier, Init.trueSettings.get("Note Skin"),
						'noteskins/notes', 'quant')),
						true, newNoteSize, newNoteSize);

					newNote.animation.add('leftScroll', [0 + (newNote.noteQuant * 4)]);
					// LOL downscroll thats so funny to me
					newNote.animation.add('downScroll', [1 + (newNote.noteQuant * 4)]);
					newNote.animation.add('upScroll', [2 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rightScroll', [3 + (newNote.noteQuant * 4)]);
				}
				else
				{
					// quant holds
					newNote.loadGraphic(Paths.image(ForeverTools.returnSkinAsset('HOLD_quants', assetModifier, Init.trueSettings.get("Note Skin"),
						'noteskins/notes', 'quant')),
						true, (assetModifier == 'pixel') ? 17 : 109, (assetModifier == 'pixel') ? 6 : 52);
					newNote.animation.add('hold', [0 + (newNote.noteQuant * 4)]);
					newNote.animation.add('holdend', [1 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rollhold', [2 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rollend', [3 + (newNote.noteQuant * 4)]);
				}

				if (assetModifier == 'pixel')
				{
					newNote.antialiasing = false;
					newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
					newNote.updateHitbox();
				}
				else
				{
					newNote.setGraphicSize(Std.int(newNote.width * 0.7));
					newNote.updateHitbox();
					newNote.antialiasing = true;
				}
		}

		//
		if (!isSustainNote)
			newNote.animation.play(UIStaticArrow.getArrowFromNumber(noteData) + 'Scroll');

		// trace(prevNote);

		if (isSustainNote && prevNote != null)
		{
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
			newNote.animation.play('holdend');
			newNote.updateHitbox();

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play('hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * (43 / 52) * 1.5 * prevNote.noteSpeed;
				prevNote.updateHitbox();
				// prevNote.setGraphicSize();
			}
		}

		return newNote;
	}
}
