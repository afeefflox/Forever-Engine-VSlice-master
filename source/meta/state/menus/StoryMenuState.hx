package meta.state.menus;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import gameObjects.userInterface.menu.*;
import gameObjects.userInterface.menu.story.*;
import meta.data.*;
import meta.data.dependency.Discord;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	static final DEFAULT_BACKGROUND_COLOR:FlxColor = FlxColor.fromString('#F9CF51');
	static final BACKGROUND_HEIGHT:Int = 400;
	var currentDifficultyId:String = 'normal';
	var currentLevelId:String = 'tutorial';
	var currentLevel:Level;
	var isLevelUnlocked:Bool;
	var currentLevelTitle:LevelTitle;
  
	var highScore:Int = 42069420;
	var highScoreLerp:Int = 12345678;
  
	var exitingMenu:Bool = false;
	var selectedLevel:Bool = false;

	var levelTitleText:FlxText;

	var scoreText:FlxText;
	var modeText:FlxText;
	var tracklistText:FlxText;

	var levelTitles:FlxTypedGroup<LevelTitle>;
	var levelProps:FlxTypedGroup<LevelProp>;
	var levelBackground:FlxSprite;

	var leftDifficultyArrow:FlxSprite;
	var rightDifficultyArrow:FlxSprite;
  
	/**
	 * The text of the difficulty selector.
	 */
	var difficultySprite:FlxSprite;
	var levelList:Array<String> = [];
  
	var difficultySprites:Map<String, FlxSprite>;
	var stickerSubState:StickerSubState;

	public function new(?stickers:StickerSubState = null)
	{
		super();
	  
		if (stickers != null)
			stickerSubState = stickers;
	}	

	override function create():Void
	{
		super.create();

		levelList = LevelRegistry.instance.listSortedLevelIds();
		levelList = levelList.filter(function(id) {
		  var levelData = LevelRegistry.instance.fetchEntry(id);
		  if (levelData == null) return false;
	
		  return levelData.isVisible();
		});
		if (levelList.length == 0) levelList = ['tutorial']; // Make sure there's at least one level to display.
	
		difficultySprites = new Map<String, FlxSprite>();
	
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		// make sure the music is playing
		ForeverTools.resetMenuMusic();

		persistentUpdate = persistentDraw = true;

		updateData();

		// Explicitly define the background color.
		this.bgColor = FlxColor.BLACK;

		updateBackground();
	
		var black:FlxSprite = new FlxSprite(levelBackground.x, 0).makeGraphic(FlxG.width, Std.int(400 + levelBackground.y), FlxColor.BLACK);
		add(black);
	
		
		levelTitles = new FlxTypedGroup<LevelTitle>();
		levelTitles.zIndex = 15;
		add(levelTitles);
	
		buildLevelTitles();
	
		leftDifficultyArrow = new FlxSprite(870, 480);
		leftDifficultyArrow.frames = Paths.getSparrowAtlas('menus/base/storymenu/ui/arrows');
		leftDifficultyArrow.animation.addByPrefix('idle', 'leftIdle0');
		leftDifficultyArrow.animation.addByPrefix('press', 'leftConfirm0');
		leftDifficultyArrow.animation.play('idle');
		add(leftDifficultyArrow);
	
		buildDifficultySprite(Constants.DEFAULT_DIFFICULTY);
		buildDifficultySprite();
	
		rightDifficultyArrow = new FlxSprite(1245, leftDifficultyArrow.y);
		rightDifficultyArrow.frames = leftDifficultyArrow.frames;
		rightDifficultyArrow.animation.addByPrefix('idle', 'rightIdle0');
		rightDifficultyArrow.animation.addByPrefix('press', 'rightConfirm0');
		rightDifficultyArrow.animation.play('idle');
		add(rightDifficultyArrow);
		add(difficultySprite);

		tracklistText = new FlxText(FlxG.width * 0.05, levelBackground.x + levelBackground.height + 100, 0, "Tracks", 32);
		tracklistText.setFormat('VCR OSD Mono', 32);
		tracklistText.alignment = CENTER;
		tracklistText.color = 0xFFE55777;
		add(tracklistText);
	
		scoreText = new FlxText(10, 10, 0, 'HIGH SCORE: 42069420');
		scoreText.setFormat('VCR OSD Mono', 32);
		scoreText.zIndex = 1000;
		add(scoreText);
	
		levelTitleText = new FlxText(FlxG.width * 0.7, 10, 0, 'LEVEL 1');
		levelTitleText.setFormat('VCR OSD Mono', 32, FlxColor.WHITE, RIGHT);
		levelTitleText.alpha = 0.7;
		levelTitleText.zIndex = 1000;
		add(levelTitleText);

		levelProps = new FlxTypedGroup<LevelProp>();
		add(levelProps);
		updateProps();
	
		updateText();
		changeDifficulty();
		changeLevel();

		#if discord_rpc
		// Updating Discord Rich Presence
		meta.data.dependency.Discord.changePresence('In the Menus', null);
		#end

		if (stickerSubState != null)
		{
			this.persistentUpdate = this.persistentDraw = true;
			openSubState(stickerSubState);
			stickerSubState.degenStickers();
		}
	}

	function updateData():Void
	{
		currentLevel = LevelRegistry.instance.fetchEntry(currentLevelId);
		isLevelUnlocked = currentLevel == null ? false : currentLevel.isUnlocked();
	}

	function buildDifficultySprite(?diff:String):Void
	{
		if (diff == null) diff = currentDifficultyId;
		remove(difficultySprite);
		difficultySprite = difficultySprites.get(diff);
		if (difficultySprite == null)
		{
		  difficultySprite = new FlxSprite(leftDifficultyArrow.x + leftDifficultyArrow.width + 10, leftDifficultyArrow.y);
	
		  if (Paths.getExistAtlas('menus/base/storymenu/difficulties/${diff}'))
		  {
			difficultySprite.frames = Paths.getSparrowAtlas('menus/base/storymenu/difficulties/${diff}');
			difficultySprite.animation.addByPrefix('idle', 'idle0', 24, true);
			difficultySprite.animation.play('idle');
		  }
		  else
			difficultySprite.loadGraphic(Paths.image('menus/base/storymenu/difficulties/${diff}'));
	
		  difficultySprites.set(diff, difficultySprite);
	
		  difficultySprite.x += (difficultySprites.get(Constants.DEFAULT_DIFFICULTY).width - difficultySprite.width) / 2;
		}
		difficultySprite.alpha = 0;
	
		difficultySprite.y = leftDifficultyArrow.y - 15;
		var targetY:Float = leftDifficultyArrow.y + 10;
		targetY -= (difficultySprite.height - difficultySprites.get(Constants.DEFAULT_DIFFICULTY).height) / 2;
		FlxTween.tween(difficultySprite, {y: targetY, alpha: 1}, 0.07);
	
		add(difficultySprite);
	}

	function buildLevelTitles():Void
	{
		levelTitles.clear();

		for (levelIndex in 0...levelList.length)
		{
		  var levelId:String = levelList[levelIndex];
		  var level:Level = LevelRegistry.instance.fetchEntry(levelId);
		  if (level == null || !level.isVisible()) continue;
	
		  // TODO: Readd lock icon if unlocked is false.
	
		  var levelTitleItem:LevelTitle = new LevelTitle(0, Std.int(levelBackground.y + levelBackground.height + 10), level);
		  levelTitleItem.targetY = ((levelTitleItem.height + 20) * levelIndex);
		  levelTitleItem.screenCenter(X);
		  levelTitles.add(levelTitleItem);
		}		
	}

	override function update(elapsed:Float):Void
	{
		highScoreLerp = Std.int(MathUtil.smoothLerp(highScoreLerp, highScore, elapsed, 0.25));

		scoreText.text = 'LEVEL SCORE: ${Math.round(highScoreLerp)}';
	
		levelTitleText.text = currentLevel.getTitle();
		levelTitleText.x = FlxG.width - (levelTitleText.width + 10); // Right align.
	
		handleKeyPresses();
	
		super.update(elapsed);
	}

	function handleKeyPresses():Void
	{
		if (exitingMenu && selectedLevel) return;

		if (controls.UI_UP_P || controls.UI_DOWN_P)
			changeLevel(controls.UI_UP_P ? -1 : 1);

		if (controls.UI_RIGHT_P || controls.UI_LEFT_P)
			changeDifficulty(controls.UI_LEFT_P ? -1 : 1);

		rightDifficultyArrow.animation.play(controls.UI_RIGHT ? 'press' : 'idle');
		rightDifficultyArrow.animation.play(controls.UI_LEFT ? 'press' : 'idle');

		if (controls.ACCEPT)
			selectLevel();

		if(controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			exitingMenu = true;
			Main.switchState(new MainMenuState());
		}
	}

	function changeLevel(change:Int = 0):Void
	{
		var currentIndex:Int = levelList.indexOf(currentLevelId);
		var prevIndex:Int = currentIndex;
	
		currentIndex += change;
	
		// Wrap around
		if (currentIndex < 0) currentIndex = levelList.length - 1;
		if (currentIndex >= levelList.length) currentIndex = 0;
	
		var previousLevelId:String = currentLevelId;
		currentLevelId = levelList[currentIndex];

		updateData();

		for (index in 0...levelTitles.members.length)
		{
		  var item:LevelTitle = levelTitles.members[index];
	
		  item.targetY = (index - currentIndex) * 125 + 480;
	
		  if (index == currentIndex)
		  {
			currentLevelTitle = item;
			item.alpha = 1.0;
		  }
		  else
		  {
			item.alpha = 0.6;
		  }
		}
	
		if (currentIndex != prevIndex) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	
		updateText();
		updateBackground(previousLevelId);
		updateProps();		
	}

	function changeDifficulty(change:Int = 0):Void
	{
		var currentIndex:Int = Constants.DEFAULT_DIFFICULTY_LIST.indexOf(currentDifficultyId);

		currentIndex += change;

		if (currentIndex < 0) currentIndex = CoolUtil.difficultyLength - 1;
		if (currentIndex >= CoolUtil.difficultyLength) currentIndex = 0;

		if (currentDifficultyId != CoolUtil.difficultyFromNumber(currentIndex))
		{
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			buildDifficultySprite();
		} 

		if (CoolUtil.difficultyLength <= 1)
			leftDifficultyArrow.visible = rightDifficultyArrow.visible = false;
		else
		    leftDifficultyArrow.visible = rightDifficultyArrow.visible = true;

		updateText();
	}

	public override function dispatchEvent(event:ScriptEvent):Void
	{
		super.dispatchEvent(event);

		if (levelProps?.members != null && levelProps.members.length > 0)
		{
		  // Dispatch event to props.
		  for (prop in levelProps.members)
		  {
			ScriptEventDispatcher.callEvent(prop, event);
		  }
		}
	}

	function selectLevel():Void
	{
		if (!currentLevel.isUnlocked())
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			return;
		}
		
		if (selectedLevel) return;
		
		selectedLevel = true;
		
		FlxG.sound.play(Paths.sound('confirmMenu'));
		
		currentLevelTitle.isFlashing = true;
		
		for (prop in levelProps.members)
		{
			prop.playConfirm();
		}	

		PlayState.storyPlaylist = currentLevel.getSongs();
		PlayState.isStoryMode = true;
		PlayState.curDifficulty = currentDifficultyId;
		PlayState.SONG = Song.loadFromJson(PlayState.curDifficulty, PlayState.storyPlaylist[0].toLowerCase());
		PlayState.storyWeek = currentLevel.id;
		PlayState.campaignScore = 0;
		Main.switchState(new PlayState());
	}

	function updateBackground(?previousLevelId:String = ''):Void
	{
		
		if (levelBackground == null || previousLevelId == '')
			{
			  // Build a new background and display it immediately.
			  levelBackground = currentLevel.buildBackground();
			  levelBackground.x = 0;
			  levelBackground.y = 56;
			  levelBackground.zIndex = 100;
			  levelBackground.alpha = 1.0; // Not hidden.
			  add(levelBackground);
			}
			else
			{
			  var previousLevel = LevelRegistry.instance.fetchEntry(previousLevelId);
		
			  if (currentLevel.isBackgroundSimple() && previousLevel.isBackgroundSimple())
			  {
				var previousColor:FlxColor = previousLevel.getBackgroundColor();
				var currentColor:FlxColor = currentLevel.getBackgroundColor();
				if (previousColor != currentColor)
				{
				  // Both the previous and current level were simple backgrounds.
				  // Fade between colors directly, rather than fading one background out and another in.
				  // cancels potential tween in progress, and tweens from there
				  FlxTween.cancelTweensOf(levelBackground);
				  FlxTween.color(levelBackground, 0.9, levelBackground.color, currentColor, {ease: FlxEase.quartOut});
				}
				else
				{
				  // Do no fade at all if the colors aren't different.
				}
			  }
			  else
			  {
				// Either the previous or current level has a complex background.
				// We need to fade the old background out and the new one in.
		
				// Reference the old background and fade it out.
				var oldBackground:FlxSprite = levelBackground;
				FlxTween.tween(oldBackground, {alpha: 0.0}, 0.6,
				  {
					ease: FlxEase.linear,
					onComplete: function(_) {
					  remove(oldBackground);
					}
				  });
		
				// Build a new background and fade it in.
				levelBackground = currentLevel.buildBackground();
				levelBackground.x = 0;
				levelBackground.y = 56;
				levelBackground.alpha = 0.0; // Hidden to start.
				levelBackground.zIndex = 100;
				add(levelBackground);
		
				FlxTween.tween(levelBackground, {alpha: 1.0}, 0.6,
				  {
					ease: FlxEase.linear
				  });
			  }
			}
	}

	function updateProps():Void
	{
		for (ind => prop in currentLevel.buildProps(levelProps.members))
		{
			if (levelProps.members[ind] != prop) levelProps.replace(levelProps.members[ind], prop) ?? levelProps.add(prop);
		}
	}

	function updateText():Void
	{
		tracklistText.text = 'TRACKS\n\n';
		tracklistText.text += currentLevel.getSongDisplayNames(currentDifficultyId).join('\n');
	  
		tracklistText.screenCenter(X);
		tracklistText.x -= FlxG.width * 0.35;
	  
		highScore = Highscore.getWeekScore(currentLevel.id, currentDifficultyId);
		// levelScore.accuracy
	}
}
