package meta.subState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import meta.MusicBeat.MusicBeatSubState;
import meta.data.font.Alphabet;
import meta.state.*;
import meta.state.menus.*;
import sys.thread.Mutex;
import sys.thread.Thread;

class PauseSubState extends MusicBeatSubState
{
	static final PAUSE_MENU_ENTRIES_STANDARD:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: resume},
		{text: 'Restart Song', callback: restartPlayState},
		{text: 'Change Difficulty', callback: switchMode.bind(_, Difficulty)},
		{text: 'Enable Practice Mode', callback: enablePracticeMode, filter: () -> !(PlayState.instance?.isPracticeMode ?? false)},
		{text: 'Exit to Menu', callback: quitToMenu},
	];

	static final PAUSE_MENU_ENTRIES_CHARTING:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: resume},
		{text: 'Restart Song', callback: restartPlayState},
		{text: 'Return to Chart Editor', callback: quitToChartEditor},
	];

	static final PAUSE_MENU_ENTRIES_DIFFICULTY:Array<PauseMenuEntry> = [
		{text: 'Back', callback: switchMode.bind(_, Standard)}
		// Other entries are added dynamically.
	];

	static final PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: resume},
		{text: 'Skip Cutscene', callback: skipVideoCutscene},
		{text: 'Restart Cutscene', callback: restartVideoCutscene},
		{text: 'Exit to Menu', callback: quitToMenu},
	];

	static final MUSIC_FADE_IN_TIME:Float = 5;
	static final MUSIC_FINAL_VOLUME:Float = 0.75;
	static final CHARTER_FADE_DELAY:Float = 15.0;
	static final CHARTER_FADE_DURATION:Float = 0.75;
  
	public static var musicSuffix:String = '';

	public static function reset():Void
		musicSuffix = '';

	public var allowInput:Bool = false;
	var currentMenuEntries:Array<PauseMenuEntry>;
	var currentMode:PauseMode;
	var background:FlxSprite;
	var metadata:FlxTypedSpriteGroup<FlxText>;
	var metadataPractice:FlxText;
	var metadataDeaths:FlxText;
	var menuEntryText:FlxTypedSpriteGroup<Alphabet>;
	var pauseMusic:FlxSound;
	var currentEntry:Int = 0;

	public function new(?params:PauseSubStateParams)
	{
		super();
		this.currentMode = params?.mode ?? Standard;
	}

	public override function create():Void
	{
		super.create();

		startPauseMusic();
	
		buildBackground();
	
		buildMetadata();
	
		regenerateMenu();
	
		transitionIn();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		handleInputs();
	}

	public override function destroy():Void
	{
		super.destroy();
		pauseMusic.stop();
	}

	function startPauseMusic():Void
	{
		pauseMusic = FlxG.sound.load(Paths.music('breakfast$musicSuffix'), true, true);
	
		if (pauseMusic == null)
		{
		  FlxG.log.warn('Could not play pause music: ${'breakfast$musicSuffix'} does not exist!');
		}
	
		// Start playing at a random point in the song.
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
		pauseMusic.fadeIn(MUSIC_FADE_IN_TIME, 0, MUSIC_FINAL_VOLUME);
	}

	function buildBackground():Void
	{
		background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0;
		background.scrollFactor.set();
		background.updateHitbox();
		add(background);
	}

	function buildMetadata():Void
	{
		metadata = new FlxTypedSpriteGroup<FlxText>();
		metadata.scrollFactor.set(0, 0);
		add(metadata);
	
		var metadataSong:FlxText = new FlxText(20, 15, FlxG.width - 40, 'Song Name');
		metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		if (PlayState.SONG != null)
		{
		  metadataSong.text = '${PlayState.SONG.song}';
		}
		metadataSong.scrollFactor.set(0, 0);
		metadata.add(metadataSong);		

		var metadataDifficulty:FlxText = new FlxText(20, metadataSong.y + 32, FlxG.width - 40, 'Difficulty: ');
		metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataDifficulty.text += CoolUtil.difficultyFromNumber(PlayState.storyDifficulty);
		metadataDifficulty.scrollFactor.set(0, 0);
		metadata.add(metadataDifficulty);
	
		metadataDeaths = new FlxText(20, metadataDifficulty.y + 32, FlxG.width - 40, '${PlayState.instance?.deathCounter} Blue Balls');
		metadataDeaths.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataDeaths.scrollFactor.set(0, 0);
		metadata.add(metadataDeaths);
	
		metadataPractice = new FlxText(20, metadataDeaths.y + 32, FlxG.width - 40, 'PRACTICE MODE');
		metadataPractice.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
		metadataPractice.scrollFactor.set(0, 0);
		metadata.add(metadataPractice);
	
		updateMetadataText();
	}


	function transitionIn():Void
	{
		FlxTween.tween(background, {alpha: 0.6}, 0.8, {ease: FlxEase.quartOut});
	  
		// Animate each element a little bit downwards.
		var delay:Float = 0.1;
		for (child in metadata.members)
		{
			FlxTween.tween(child, {alpha: 1, y: child.y + 5}, 1.8, {ease: FlxEase.quartOut, startDelay: delay});
			delay += 0.1;
		}
	  
		new FlxTimer().start(0.2, (_) -> {
			allowInput = true;
		});
	}

	function handleInputs():Void
	{
		if (!allowInput) return;

		if (controls.UI_UP_P || controls.UI_DOWN_P)
			changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.ACCEPT)
			currentMenuEntries[currentEntry].callback(this);
		else if (controls.PAUSE)
			resume(this);
	}

	function changeSelection(change:Int = 0):Void
	{
		var prevEntry:Int = currentEntry;
		currentEntry += change;
	
		if (currentEntry < 0) currentEntry = currentMenuEntries.length - 1;
		if (currentEntry >= currentMenuEntries.length) currentEntry = 0;
	
		if (currentEntry != prevEntry) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	
		var bullShit:Int = 0;
		for (item in menuEntryText.members)
		{
			item.targetY = bullShit - currentEntry;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function regenerateMenu(?targetMode:PauseMode):Void
	{
		if (targetMode == null) targetMode = this.currentMode;

		var previousMode:PauseMode = this.currentMode;
		this.currentMode = targetMode;
	
		resetSelection();
		chooseMenuEntries();
		clearAndAddMenuEntries();
		updateMetadataText();
		changeSelection();
	}

	function resetSelection():Void
		this.currentEntry = 0;

	function chooseMenuEntries():Void
	{
		switch (this.currentMode)
		{
		  case PauseMode.Standard:
			currentMenuEntries = PAUSE_MENU_ENTRIES_STANDARD.clone();
		  case PauseMode.Charting:
			currentMenuEntries = PAUSE_MENU_ENTRIES_CHARTING.clone();
		  case PauseMode.Difficulty:
			// Prepend the difficulties.
			var entries:Array<PauseMenuEntry> = [];
			for (i in 0...Constants.DEFAULT_DIFFICULTY_LIST.length)
			{
				entries.push({text: CoolUtil.difficultyFromNumber(i), callback: (state) -> changeDifficulty(state, i)});
			}
			// Add the back button.
			currentMenuEntries = entries.concat(PAUSE_MENU_ENTRIES_DIFFICULTY.clone());
		  case PauseMode.Cutscene:
			currentMenuEntries = PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE.clone();
		}
	}

	function clearAndAddMenuEntries():Void
	{
		if (menuEntryText == null)
		{
			menuEntryText = new FlxTypedSpriteGroup<Alphabet>();
			menuEntryText.scrollFactor.set(0, 0);
			add(menuEntryText);
		}
		menuEntryText.clear();
		var entryIndex:Int = 0;
		var toRemove = [];
		for (entry in currentMenuEntries)
		{
		  if (entry == null || (entry.filter != null && !entry.filter()))
		  {
			// Remove entries that should be hidden.
			toRemove.push(entry);
		  }
		  else
		  {
			// Handle visible entries.
			var yPos:Float = 70 * entryIndex + 30;

			var text:Alphabet = new Alphabet(0, yPos, entry.text, true, false);
			text.isMenuItem = true;
			text.scrollFactor.set(0, 0);
			text.alpha = 0;
			menuEntryText.add(text);
			entryIndex++;
		  }
		}
		for (entry in toRemove)
		{
		  currentMenuEntries.remove(entry);
		}
	}

	function updateMetadataText():Void
	{
		metadataPractice.visible = PlayState.instance?.isPracticeMode ?? false;
	  
		switch (this.currentMode)
		{
			case Standard | Difficulty:
			  metadataDeaths.text = '${PlayState.instance?.deathCounter} Blue Balls';
			case Charting:
			  metadataDeaths.text = 'Chart Editor Preview';
			case Cutscene:
			  metadataDeaths.text = 'Video Paused';
		}
	}

	static function resume(state:PauseSubState):Void
	{
		state.close();

	}

	static function switchMode(state:PauseSubState, targetMode:PauseMode):Void
	{
		state.regenerateMenu(targetMode);
	}

	static function changeDifficulty(state:PauseSubState, curSelected:Int):Void
	{
		var poop = Highscore.formatSong(PlayState.SONG.song, curSelected);
		PlayState.SONG = Song.loadFromJson(poop, PlayState.SONG.song);
		PlayState.storyDifficulty = curSelected;
		FlxG.resetState();
		state.close();
	}

	static function restartPlayState(state:PauseSubState):Void
	{
		FlxG.resetState();
		state.close();
	}

	static function enablePracticeMode(state:PauseSubState):Void
	{
		PlayState.instance.isPracticeMode = true;
		state.regenerateMenu();
	}

	static function restartVideoCutscene(state:PauseSubState):Void
	{
		state.close();

	}

	static function skipVideoCutscene(state:PauseSubState):Void
	{
		state.close();
	}

	static function quitToMenu(state:PauseSubState):Void
	{
		state.allowInput = false;

		PlayState.resetMusic();
		state.openSubState(new StickerSubState(null, (sticker) -> PlayState.isStoryMode ? new StoryMenuState(sticker) :  new FreeplayState(sticker)));
	}

	static function quitToChartEditor(state:PauseSubState):Void
	{
		Main.switchState(new meta.state.editors.ChartingState());
		state.close();
	}
}

typedef PauseSubStateParams =
{
  /**
   * Which mode to start in. Dictates what entries are displayed.
   */
  ?mode:PauseMode,
};


/**
 * Which set of options the pause menu should display.
 */
 enum PauseMode
 {
   /**
	* The menu displayed when the player pauses the game during a song.
	*/
   Standard;
 
   /**
	* The menu displayed when the player pauses the game during a song while in charting mode.
	*/
   Charting;
 
   /**
	* The menu displayed when the player moves to change the game's difficulty.
	*/
   Difficulty;
   
   /**
	* The menu displayed when the player pauses the game during a video cutscene.
	*/
   Cutscene;
 }
 
 /**
  * Represents a single entry in the pause menu.
  */
 typedef PauseMenuEntry =
 {
   /**
	* The text to display for this entry.
	* TODO: Implement localization.
	*/
   var text:String;
 
   /**
	* The callback to execute when the user selects this entry.
	*/
   var callback:PauseSubState->Void;
 
   /**
	* If this returns true, the entry will be displayed. If it returns false, the entry will be hidden.
	*/
   var ?filter:Void->Bool;
 
   // Instance-specific properties
 };