package meta.state.menus;

import gameObjects.userInterface.menu.story.Level;

using StringTools;

class FreeplayState extends MusicBeatState
{
	//
	public var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	public var curSelected:Int = 0;
	public var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;
	public var currentVariation:String = Constants.DEFAULT_VARIATION;
	public var currentCharacter:String = Constants.DEFAULT_CHARACTER;
	public var currentInstrumental:String = null;

	public static var rememberedDifficulty:String = Constants.DEFAULT_DIFFICULTY;
	public static var rememberedSongId:Null<String> = 'tutorial';
	public static var rememberedVariation:String = Constants.DEFAULT_VARIATION;
	public static var rememberedCharacter:String = Constants.DEFAULT_CHARACTER;

	var scoreText:FlxText;
	var diffText:FlxText;
	var vartionsText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	public static var instance:FreeplayState;

	public var grpSongs:FlxTypedGroup<Alphabet>;

	private var iconArray:Array<HealthIcon> = [];
	private var scoreBG:FlxSprite;

	public static var hideBaseGame:Bool = false;
	var stickerSubState:StickerSubState;

	public function new(?stickers:StickerSubState)
	{
		super();
		
		if (stickers != null)
			stickerSubState = stickers;
	}

	function rememberSelection():Void
	{
		if (rememberedSongId != null)
		{
			curSelected = songs.findIndex(function(song) {
				if (song == null) return false;
				return song.data.id == rememberedSongId;
			});
		
			if (curSelected == -1) curSelected = 0;
		}

		if (rememberedDifficulty != null) currentDifficulty = rememberedDifficulty;
		if(rememberedVariation != null) currentVariation = rememberedVariation;
		if(rememberedCharacter != null) currentCharacter = rememberedCharacter;
	}

	override function create()
	{
		super.create();

		instance = this;

		rememberSelection();
		
		for (levelId in LevelRegistry.instance.listSortedLevelIds())
		{
			var level:Level = LevelRegistry.instance.fetchEntry(levelId);

			if (level == null || hideBaseGame && (level.id == 'week1' || level.id == 'tutorial')) continue;
			
			for (songId in level.getSongs())
			{
				var song:Null<Song> = SongRegistry.instance.fetchEntry(songId);

				if (song == null)
				{
					trace('[WARN] Could not find song with id (${songId})');
					continue;
				}
				songs.push(new SongMetadata(song, level));
			}
		}
		
		#if discord_rpc
		Discord.changePresence('MENU SCREEN', 'Freeplay Menu');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/base/menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		
		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].data.id, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			
			var icon:HealthIcon = new HealthIcon(CharacterRegistry.fetchCharacterData(songs[i].data.songCharacter).healthIcon.id);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
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

		vartionsText = new FlxText(diffText.x, diffText.y + 36, 0, "", 24);
		vartionsText.alignment = CENTER;
		vartionsText.font = scoreText.font;
		vartionsText.x = diffText.x;
		add(vartionsText);

		add(scoreText);

		

		selector = new FlxText();
		selector.size = 40;
		selector.text = ">";

		if (stickerSubState != null)
		{
			this.persistentUpdate = this.persistentDraw = true;
			openSubState(stickerSubState);
			stickerSubState.degenStickers();
		}
	}

	var loadedSong:String = "";
	override function update(elapsed:Float)
	{
		super.update(elapsed);

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

		if(FlxG.keys.justPressed.CONTROL)
			openSubState(new FreeplayOptionSubstate());

		if (controls.ACCEPT)
		{
			PlayStatePlaylist.isStoryMode = false;

			var targetSongId:String = songs[curSelected].data.id ?? 'unknown';
			var targetSongNullable:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
			if (targetSongNullable == null)
			{
				FlxG.log.warn('WARN: could not find song with id (${targetSongId})');
				return;
			}

			var targetSong:Song = targetSongNullable;
			var targetVariation:Null<String> = currentVariation;
			var targetLevelId:Null<String> = songs[curSelected].levelId;
			PlayStatePlaylist.campaignId = targetLevelId ?? null;
			var targetDifficulty:Null<SongDifficulty> = targetSong.getDifficulty(currentDifficulty, currentVariation);
			if (targetDifficulty == null)
			{
				FlxG.log.warn('WARN: could not find difficulty with id (${currentDifficulty})');
				return;
			}

			if (currentInstrumental == null)
			{
				var baseInstrumentalId:String = targetSong?.getBaseInstrumentalId(currentDifficulty, targetDifficulty.variation ?? Constants.DEFAULT_VARIATION) ?? '';
				currentInstrumental = baseInstrumentalId;
			}

			FunkinSound.playOnce(Paths.sound('confirmMenu'));
			LoadingSubState.loadPlayState({
				targetSong: targetSong,
				targetDifficulty: currentDifficulty,
				targetVariation: currentVariation,
				targetInstrumental: currentInstrumental
			}, true);

		}

		// Adhere the position of all the things (I'm sorry it was just so ugly before I had to fix it Shubs)
		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreText.x = FlxG.width - scoreText.width - 5;
		scoreBG.width = scoreText.width + 8;
		scoreBG.x = FlxG.width - scoreBG.width;
		diffText.x = scoreBG.x + (scoreBG.width * 0.5) - (diffText.width * 0.5);
	}
	

	public function changeDiff(change:Int = 0)
	{
		var previousVariation:String = currentVariation;
		var characterVariations:Array<String> = songs[curSelected].data.getVariationsByCharacterId(currentCharacter) ?? Constants.DEFAULT_VARIATION_LIST;
		var difficultiesAvailable:Array<String> = songs[curSelected].data.listDifficulties(null, characterVariations) ?? Constants.DEFAULT_DIFFICULTY_LIST;
		var currentDifficultyIndex:Int = difficultiesAvailable.indexOf(currentDifficulty);
		if (currentDifficultyIndex == -1) currentDifficultyIndex = difficultiesAvailable.indexOf(Constants.DEFAULT_DIFFICULTY);
		currentDifficultyIndex += change;

		if (currentDifficultyIndex < 0) currentDifficultyIndex = Std.int(difficultiesAvailable.length - 1);
		if (currentDifficultyIndex >= difficultiesAvailable.length) currentDifficultyIndex = 0;

		currentDifficulty = difficultiesAvailable[currentDifficultyIndex];
		rememberedDifficulty = currentDifficulty;
		for (variation in characterVariations)
		{
			if (songs[curSelected].data.hasDifficulty(currentDifficulty, variation) ?? false)
			{
				currentVariation = variation;
				rememberedVariation = variation;
				break;
			}
		}

		intendedScore = Highscore.getScore(songs[curSelected].data.id, currentDifficulty);

		diffText.text = '< ' + currentDifficulty.toUpperCase() + ' >';
		vartionsText.text = '< ' + currentVariation.toUpperCase() + ' >';
		if (currentVariation != previousVariation) playCurSongPreview();
	}

	public function changeSelection(change:Int = 0)
	{
		var prevSelected:Int = curSelected;
		curSelected += change;

		if (curSelected != prevSelected) FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);
		
		if (curSelected < 0) curSelected = songs.length - 1;
		if (curSelected >= songs.length) curSelected = 0;

		intendedScore = Highscore.getScore(songs[curSelected].data.id, currentDifficulty);
		rememberedSongId = songs[curSelected].data.id;

		var bullShit:Int = 0;

		for (i in 0...iconArray.length) iconArray[i].alpha = 0.6;
		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			if (item.targetY == 0) item.alpha = 1;
		}

		if (songs.length > 0)
		{
			playCurSongPreview();
			grpSongs.members[curSelected].alpha = 1;
		}

		changeDiff();
	}

	function playCurSongPreview():Void
	{
		var previewSong:Null<Song> = songs[curSelected]?.data;
		if (previewSong == null) return;

		var songDifficulty:Null<SongDifficulty> = previewSong.getDifficulty(currentDifficulty, currentVariation);

		var baseInstrumentalId:String = previewSong.getBaseInstrumentalId(currentDifficulty, songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? '';
		var altInstrumentalIds:Array<String> = previewSong.listAltInstrumentalIds(currentDifficulty,
		  songDifficulty?.variation ?? Constants.DEFAULT_VARIATION) ?? [];
		var instSuffix:String = baseInstrumentalId;
		instSuffix = (instSuffix != '') ? '-$instSuffix' : '';
		FunkinSound.playMusic(previewSong.id,
		{
			startingVolume: 0.0,
			overrideExisting: true,
			restartTrack: false,
			mapTimeChanges: false,
			pathsFunction: INST,
			suffix: instSuffix,
			partialParams: {loadPartial: true, start: 0, end: 0.2},
			onLoad: function() {FlxG.sound.music.fadeIn(2, 0, 0.4);}
		});

		if (songDifficulty != null)
		{
			Conductor.instance.mapTimeChanges(songDifficulty.timeChanges);
			Conductor.instance.update(FlxG.sound?.music?.time ?? 0.0);
		}
	}
}

class SongMetadata
{
	public var data:Song;
	public var levelId(get, never):Null<String>;

	function get_levelId():Null<String> return _levelId;
	var _levelId:String;
	public var isFav:Bool = false;
	public var songCharacter(get, never):String;
	public var fullSongName(get, never):String;

	public function new(data:Song, levelData:Level)
	{
		this.data = data;
		_levelId = levelData.id;
	}

	function get_songCharacter():String
	{
		var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacter);
		return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.characters.opponent ?? '';
	}

	function get_fullSongName():String
	{
		var variations:Array<String> = data.getVariationsByCharacterId(FreeplayState.rememberedCharacter);
		return data.getDifficulty(FreeplayState.rememberedDifficulty, null, variations)?.songName ?? data.songName;
	}
}
