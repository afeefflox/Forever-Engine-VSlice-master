package meta.state.menus;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.ColorTween;
import flixel.util.FlxColor;
import gameObjects.userInterface.HealthIcon;
import lime.utils.Assets;
import meta.data.*;
import meta.data.Song.SwagSong;
import meta.data.dependency.Discord;
import meta.data.font.Alphabet;
import openfl.media.Sound;
import gameObjects.userInterface.menu.story.Level;
import sys.FileSystem;
#if target.threaded
import sys.thread.Mutex;
import sys.thread.Thread;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	//
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	private var mainColor = FlxColor.WHITE;
	private var bg:FlxSprite;
	private var scoreBG:FlxSprite;

	private var existingSongs:Array<String> = [];
	private var existingDifficulties:Array<Array<String>> = [];
	var stickerSubState:StickerSubState;

	public function new(?stickers:StickerSubState)
	{
		super();
		
		if (stickers != null)
			stickerSubState = stickers;

	}

	override function create()
	{
		super.create();

		/**
			Wanna add songs? They're in the Main state now, you can just find the week array and add a song there to a specific week.
			Alternatively, you can make a folder in the Songs folder and put your songs there, however, this gives you less
			control over what you can display about the song (color, icon, etc) since it will be pregenerated for you instead.
		**/
		// load in all songs that exist in folder
		var folderSongs:Array<String> = CoolUtil.returnAssetsLibrary('songs', 'assets');

		for (levelId in LevelRegistry.instance.listSortedLevelIds())
		{
			var level:Level = LevelRegistry.instance.fetchEntry(levelId);

			if (level == null)
			{
			  trace('[WARN] Could not find level with id (${levelId})');
			  continue;
			}

			for (songId in level.getSongs())
			{
				if (!existingSongs.contains(songId.toLowerCase()))
				{
					var icon:String = 'gf';
					var castSong:SwagSong = null;
					//idk :/
					if (Paths.exists(Paths.charts(songId, 'hard'), TEXT))
						castSong = Song.loadFromJson('hard', songId);
					else if (Paths.exists(Paths.charts(songId, 'normal'), TEXT))
						castSong = Song.loadFromJson('normal', songId);
					else
						castSong = Song.loadFromJson('easy', songId);

					icon = (CharacterRegistry.fetchCharacterData(castSong.characters[1]) != null) ? CharacterRegistry.fetchCharacterData(castSong.characters[1]).healthIcon.id : 'bf';
					addSong(CoolUtil.spaceToDash(songId), level.id, icon, FlxColor.WHITE);
				}				
			}
		}

		#if discord_rpc
		Discord.changePresence('MENU SCREEN', 'Freeplay Menu');
		#end

		// LOAD CHARACTERS
		bg = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - scoreText.width, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.alignment = CENTER;
		diffText.font = scoreText.font;
		diffText.x = scoreBG.getGraphicMidpoint().x;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";

		if (stickerSubState != null)
		{
			this.persistentUpdate = this.persistentDraw = true;
			openSubState(stickerSubState);
			stickerSubState.degenStickers();
		}
		
		// add(selector);
	}

	public function addSong(songName:String, week:String, songCharacter:String, songColor:FlxColor)
	{
		///*
		var coolDifficultyArray = [];
		for (i in Constants.DEFAULT_DIFFICULTY_LIST)
			if (Paths.exists(Paths.charts(songName, i), TEXT))
				coolDifficultyArray.push(i);

		if (coolDifficultyArray.length > 0)
		{
			songs.push(new SongMetadata(songName, week, songCharacter, songColor));
			existingDifficulties.push(coolDifficultyArray);
		}
	}
	var loadedSong:String = "";
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxTween.color(bg, 0.35, bg.color, mainColor);

		var lerpVal = Main.framerateAdjust(0.1);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, lerpVal));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (controls.UI_UP_P || controls.UI_DOWN_P)
			changeSelection(controls.UI_UP_P ? -1 : 1);

		if (controls.UI_LEFT_P || controls.UI_RIGHT_P)
			changeDiff(controls.UI_LEFT_P ? -1 : 1);

		if (controls.BACK)
			Main.switchState(new MainMenuState());

		if (controls.ACCEPT)
		{
			PlayState.SONG = Song.loadFromJson(existingDifficulties[curSelected][curDifficulty], songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.curDifficulty = existingDifficulties[curSelected][curDifficulty];

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK ' + PlayState.storyWeek);

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
			Main.switchState(new PlayState());
		}

		// Adhere the position of all the things (I'm sorry it was just so ugly before I had to fix it Shubs)
		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreText.x = FlxG.width - scoreText.width - 5;
		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;
		diffText.x = scoreBG.x + (scoreBG.width * 0.5) - (diffText.width * 0.5);
	}

	var lastDifficulty:String;

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;
		if (lastDifficulty != null && change != 0)
			while (existingDifficulties[curSelected][curDifficulty] == lastDifficulty)
				curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = existingDifficulties[curSelected].length - 1;
		if (curDifficulty > existingDifficulties[curSelected].length - 1)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, existingDifficulties[curSelected][curDifficulty]);

		diffText.text = '< ' + existingDifficulties[curSelected][curDifficulty].toUpperCase() + ' >';
		lastDifficulty = existingDifficulties[curSelected][curDifficulty];
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, songs.length - 1);
		intendedScore = Highscore.getScore(songs[curSelected].songName, existingDifficulties[curSelected][curDifficulty]);


		mainColor = songs[curSelected].songColor;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}

		changeDiff();
		if (songs[curSelected].songName != loadedSong)
		{
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName));
			if (FlxG.sound.music.fadeTween != null)
				FlxG.sound.music.fadeTween.cancel();
			FlxG.sound.music.volume = 0.0;
			FlxG.sound.music.fadeIn(1.0, 0.0, 1.0);
			loadedSong = songs[curSelected].songName;
		}
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:String = "";
	public var songCharacter:String = "";
	public var songColor:FlxColor = FlxColor.WHITE;

	public function new(song:String, week:String, songCharacter:String, songColor:FlxColor)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.songColor = songColor;
	}
}
