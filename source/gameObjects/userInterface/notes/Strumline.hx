package gameObjects.userInterface.notes;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import meta.data.Conductor;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

class UIStaticArrow extends FlxSprite
{
	/*  Oh hey, just gonna port this code from the previous Skater engine 
		(depending on the release of this you might not have it cus I might rewrite skater to use this engine instead)
		It's basically just code from the game itself but
		it's in a separate class and I also added the ability to set offsets for the arrows.

		uh hey you're cute ;)
	 */
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var babyArrowType:Int = 0;
	public var canFinishAnimation:Bool = true;

	public var initialX:Int;
	public var initialY:Int;

	public var xTo:Float;
	public var yTo:Float;
	public var angleTo:Float;

	public var setAlpha:Float = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.6;
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote(PlayState.assetModifier);
		}
		return value;
	}
	public function new(x:Float, y:Float, ?babyArrowType:Int = 0)
	{
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();

		this.babyArrowType = babyArrowType;

		var skin:String = 'NOTE_assets';
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		texture = skin; //Load texture and anims

		updateHitbox();
		scrollFactor.set();
	}

	public function reloadNote(assetModifier:String = 'base') {
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		switch(assetModifier)
		{
			case 'pixel':
				loadGraphic(Paths.image(ForeverTools.returnSkinAsset(texture, assetModifier, Init.trueSettings.get("Note Skin"),
					'noteskins/notes')), true,
					17, 17);
				animation.add('static', [babyArrowType]);
				animation.add('pressed', [4 + babyArrowType, 8 + babyArrowType], 12, false);
				animation.add('confirm', [12 + babyArrowType, 16 + babyArrowType], 24, false);
				antialiasing = false;
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));

				addOffset('static', -67, -50);
				addOffset('pressed', -67, -50);
				addOffset('confirm', -67, -50);

			case 'chart editor':
				loadGraphic(Paths.image('UI/forever/base/chart editor/note_array'), true, 157, 156);
				animation.add('static', [babyArrowType]);
				animation.add('pressed', [16 + babyArrowType], 12, false);
				animation.add('confirm', [4 + babyArrowType, 8 + babyArrowType, 16 + babyArrowType], 24, false);
			default:
				frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(texture, assetModifier,
					Init.trueSettings.get("Note Skin"), 'noteskins/notes'));

				animation.addByPrefix('static', 'arrow' + getArrowFromNumber(babyArrowType).toUpperCase());
				animation.addByPrefix('pressed', getArrowFromNumber(babyArrowType) + ' press', 24, false);
				animation.addByPrefix('confirm', getArrowFromNumber(babyArrowType) + ' confirm', 24, false);

				antialiasing = true;
				setGraphicSize(Std.int(width * 0.7));

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (babyArrowType > 0 && babyArrowType < 3)
				{
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (babyArrowType == 1)
					{
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}

				addOffset('pressed', -2, -2);
				addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}
		updateHitbox();

		if(lastAnim != null) playAnim(lastAnim, true);
	}

	// literally just character code
	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (AnimName == 'confirm')
			alpha = 1;
		else
			alpha = setAlpha;

		animation.play(AnimName, Force, Reversed, Frame);
		updateHitbox();

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];

	public static function getArrowFromNumber(numb:Int)
	{
		// yeah no I'm not writing the same shit 4 times over
		// take it or leave it my guy
		var stringSect:String = '';
		switch (numb)
		{
			case(0):
				stringSect = 'left';
			case(1):
				stringSect = 'down';
			case(2):
				stringSect = 'up';
			case(3):
				stringSect = 'right';
		}
		return stringSect;
		//
	}

	// that last function was so useful I gave it a sequel
	public static function getColorFromNumber(numb:Int)
	{
		var stringSect:String = '';
		switch (numb)
		{
			case(0):
				stringSect = 'purple';
			case(1):
				stringSect = 'blue';
			case(2):
				stringSect = 'green';
			case(3):
				stringSect = 'red';
		}
		return stringSect;
		//
	}
}

class Strumline extends FlxTypedGroup<FlxBasic>
{
	//
	public var receptors:FlxTypedGroup<UIStaticArrow>;
	public var splashNotes:FlxTypedGroup<NoteSplash>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var autoplay:Bool = true;
	public var displayJudgements:Bool = false;
	public var noteSplashes:Bool = false;
	public function new(x:Float = 0, ?displayJudgements:Bool = true, ?autoplay:Bool = true,
			?noteSplashes:Bool = false, ?keyAmount:Int = 4, ?downscroll:Bool = false, ?parent:Strumline)
	{
		super();

		receptors = new FlxTypedGroup<UIStaticArrow>();
		splashNotes = new FlxTypedGroup<NoteSplash>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();

		allNotes = new FlxTypedGroup<Note>();

		this.autoplay = autoplay;
		this.displayJudgements = displayJudgements;
		this.noteSplashes = noteSplashes;

		for (i in 0...keyAmount)
		{
			var staticArrow:UIStaticArrow = new UIStaticArrow(-25 + x, 25 + (downscroll ? FlxG.height - 200 : 0), i);
			staticArrow.ID = i;

			staticArrow.x -= ((keyAmount * 0.5) * Note.swagWidth);
			staticArrow.x += (Note.swagWidth * i);
			receptors.add(staticArrow);

			staticArrow.initialX = Math.floor(staticArrow.x);
			staticArrow.initialY = Math.floor(staticArrow.y);
			staticArrow.angleTo = 0;
			staticArrow.y -= 10;
			staticArrow.playAnim('static');

			staticArrow.alpha = 0;
			FlxTween.tween(staticArrow, {y: staticArrow.initialY, alpha: staticArrow.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
		}

		if (Init.trueSettings.get("Clip Style").toLowerCase() == 'stepmania')
			add(holdsGroup);
		add(receptors);
		if (Init.trueSettings.get("Clip Style").toLowerCase() == 'fnf')
			add(holdsGroup);
		add(notesGroup);
		if (splashNotes != null)
			add(splashNotes);
	}

	public function createSplash(coolNote:Note)
	{
		if(coolNote != null && noteSplashes) 
		{
			var strum:UIStaticArrow = receptors.members[coolNote.noteData];
			if(strum != null)
				spawnNoteSplash(this, strum.x, strum.y, coolNote.noteData, coolNote);
		}
	}

	public function spawnNoteSplash(strumline:Strumline, x:Float, y:Float, data:Int, ?note:Note = null) {
		var splash:NoteSplash = splashNotes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, PlayState.assetModifier, note);
		splashNotes.add(splash);
	}

	public function push(newNote:Note)
	{
		//
		var chosenGroup = (newNote.isSustainNote ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!Init.trueSettings.get('Downscroll')) ? FlxSort.DESCENDING : FlxSort.ASCENDING);
	}
}
