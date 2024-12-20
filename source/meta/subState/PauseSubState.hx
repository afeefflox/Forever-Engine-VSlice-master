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
		{text: 'Options', callback: openOption},
		{text: 'Exit to Menu', callback: quitToMenu},
	];

	static final PAUSE_MENU_ENTRIES_CHARTING:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: resume},
		{text: 'Restart Song', callback: restartPlayState},
		{text: 'Options', callback: openOption},
		{text: 'Return to Chart Editor', callback: quitToChartEditor},
		{text: 'Exit to Menu', callback: quitToMenu}, //imagine stuck in a loop forever lmao
	];

	static final PAUSE_MENU_ENTRIES_DIFFICULTY:Array<PauseMenuEntry> = [
		{text: 'Back', callback: switchMode.bind(_, Standard)}
		// Other entries are added dynamically.
	];

	static final PAUSE_MENU_ENTRIES_VIDEO_CUTSCENE:Array<PauseMenuEntry> = [
		{text: 'Resume', callback: resume},
		{text: 'Skip Cutscene', callback: skipVideoCutscene},
		{text: 'Restart Cutscene', callback: restartVideoCutscene},
		{text: 'Options', callback: openOption},
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
	var metadataArtist:FlxText;
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
		startCharterTimer();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		handleInputs();
	}

	public override function destroy():Void
	{
		super.destroy();
		charterFadeTween.cancel();
		charterFadeTween = null;
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
		background = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, FlxColor.BLACK);
		background.alpha = 0;
		background.scrollFactor.set();
		background.updateHitbox();
		add(background);
	}

	function buildMetadata():Void
	{
		metadata = new FlxTypedSpriteGroup<FlxText>();
		metadata.scrollFactor.set();
		add(metadata);

		var metadataSong:FlxText = new FlxText(20, 15, FlxG.width - 40, 'Song Name');
		metadataSong.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataSong.text = '${PlayState.instance.currentChart.songName}';
		metadataSong.scrollFactor.set();
		metadata.add(metadataSong);

		metadataArtist = new FlxText(20, metadataSong.y + 32, FlxG.width - 40, 'Artist: ${Constants.DEFAULT_ARTIST}');
		metadataArtist.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataArtist.text = 'Artist: ${PlayState.instance.currentChart.songArtist}';
		metadataArtist.scrollFactor.set();
		metadata.add(metadataArtist);

		var metadataDifficulty:FlxText = new FlxText(20, metadataArtist.y + 32, FlxG.width - 40, 'Difficulty: ');
		metadataDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, FlxTextAlign.RIGHT);
		metadataDifficulty.text += PlayState.instance.currentDifficulty.replace('-', ' ').toTitleCase();
		metadataDifficulty.scrollFactor.set();
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

	var charterFadeTween:Null<FlxTween> = null;
	function startCharterTimer():Void
	{
		charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION,{
			startDelay: CHARTER_FADE_DELAY,
			ease: FlxEase.quartOut,
			onComplete: (_) -> {
				metadataArtist.text = 'Charter: ${PlayState.instance.currentChart.charter ?? Constants.DEFAULT_CHARTER}';
				FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION, {ease: FlxEase.quartOut,  onComplete: (_) -> {startArtistTimer();}});
			}
		});
	}

	function startArtistTimer():Void
	{
		charterFadeTween = FlxTween.tween(metadataArtist, {alpha: 0.0}, CHARTER_FADE_DURATION,{
			startDelay: CHARTER_FADE_DELAY,
			ease: FlxEase.quartOut,
			onComplete: (_) -> {
				metadataArtist.text = 'Artist: ${PlayState.instance.currentChart.songArtist ?? Constants.DEFAULT_ARTIST}';
				FlxTween.tween(metadataArtist, {alpha: 1.0}, CHARTER_FADE_DURATION,{ease: FlxEase.quartOut, onComplete: (_) -> {startCharterTimer();}});
			}
		});
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
			if (item.targetY == 0) item.alpha = 1;
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
			var entries:Array<PauseMenuEntry> = [];
			var difficultiesInVariation = PlayState.instance.currentSong.listDifficulties(PlayState.instance.currentChart.variation, true);
			for (difficulty in difficultiesInVariation) entries.push({text: difficulty.toTitleCase(), callback: (state) -> changeDifficulty(state, difficulty)});
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
		VideoCutscene.resume();
		state.close();
	}

	static function switchMode(state:PauseSubState, targetMode:PauseMode):Void
	{
		state.regenerateMenu(targetMode);
	}

	static function openOption(state:PauseSubState):Void
	{
		meta.state.menus.OptionsMenuState.isPlayState = true;

		PlayState.instance.deathCounter = PlayState.instance.songScore = 0;
		PlayState.resetMusic();
		
		Highscore.instance.resetTallies();
		Timings.callAccuracy();
		Timings.updateAccuracy(0);
		
		Main.switchState(new meta.state.menus.OptionsMenuState());
		state.close();
	}

	static function changeDifficulty(state:PauseSubState, difficulty:String):Void
	{
		PlayState.instance.currentSong = SongRegistry.instance.fetchEntry(PlayState.instance.currentSong.id.toLowerCase());
		PlayStatePlaylist.campaignScore = 0;
		PlayStatePlaylist.campaignDifficulty = difficulty;
		PlayState.instance.currentDifficulty = PlayStatePlaylist.campaignDifficulty;
		PlayState.instance.needsReset = true;
		FreeplayState.rememberedDifficulty = difficulty;

		state.close();
	}

	static function restartPlayState(state:PauseSubState):Void
	{
		PlayState.instance.needsReset = true;
		state.close();
	}

	static function enablePracticeMode(state:PauseSubState):Void
	{
		if (PlayState.instance == null) return;
		PlayState.instance.isPracticeMode = true;
		state.regenerateMenu();
	}

	static function restartVideoCutscene(state:PauseSubState):Void
	{
		VideoCutscene.restart();
		state.close();
	}

	static function skipVideoCutscene(state:PauseSubState):Void
	{
		VideoCutscene.finish();
		state.close();
	}

	static function quitToMenu(state:PauseSubState):Void
	{
		state.allowInput = false;
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;

		PlayState.instance.deathCounter = PlayState.instance.songScore = 0;
		PlayState.resetMusic();
		
		Highscore.instance.resetTallies();
		Timings.callAccuracy();
		Timings.updateAccuracy(0);

		state.openSubState(new StickerSubState(null, (sticker) -> PlayStatePlaylist.isStoryMode ? new StoryMenuState(sticker) : FreeplayState.build(null, sticker)));
	}

	static function quitToChartEditor(state:PauseSubState):Void
	{
		if (FlxG.sound.music != null) FlxG.sound.music.pause(); // Don't reset song position!
		PlayState.instance.close();
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