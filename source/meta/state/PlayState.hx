package meta.state;

import meta.state.editors.charting.ChartEditorState;
import flixel.addons.transition.FlxTransitionableState;
#if desktop
import meta.data.dependency.Discord;
#end

class PlayState extends MusicBeatSubState
{
	public static var instance:PlayState;

	public var currentStage(get, never):String;
	public static var lastParams:PlayStateParams = null;
	public var currentSong:Song = null;
	public var currentDifficulty:String = Constants.DEFAULT_DIFFICULTY;
	public var currentVariation:String = Constants.DEFAULT_VARIATION;
	public var currentInstrumental:String = '';

	public var currentChart(get, never):SongDifficulty;

	function get_currentChart():SongDifficulty
	{
		if (currentSong == null || currentDifficulty == null) return null;
		return currentSong.getDifficulty(currentDifficulty, currentVariation);
	}

	function get_currentStage():String
	{
		if (currentChart == null || currentChart.stage == null || currentChart.stage == '') return Constants.DEFAULT_STAGE;
		return currentChart.stage;
	}
	
	public var dad(get, never):BaseCharacter;
	public var gf(get, never):BaseCharacter;
	public var boyfriend(get, never):BaseCharacter;
	public var stage:Stage = null;
	public var vocals:VoicesGroup;
	function get_boyfriend():BaseCharacter
	{
		if (stage != null)  return stage.getBoyfriend();
		return null;
	}
	function get_gf():BaseCharacter
	{
		if (stage != null)  return stage.getGirlfriend();
		return null;
	}
	function get_dad():BaseCharacter
	{
		if (stage != null)  return stage.getDad();
		return null;
	}

	var songEvents:Array<SongEventData>;

	public var cameraFollowPoint:FlxObject;
	public var cameraFollowTween:FlxTween;
	public var cameraZoomTween:FlxTween;
	public var scrollSpeedTweens:Array<FlxTween> = [];
	
	public var previousCameraFollowPoint:FlxPoint = null;
	public var currentCameraZoom:Float = FlxCamera.defaultZoom;
	public var cameraBopMultiplier:Float = 1.0;
	public var stageZoom(get, never):Float;
	public var disableCamera:Bool = false;
	function get_stageZoom():Float
	{
		if (stage != null) return stage.camZoom;
		else
			return FlxCamera.defaultZoom * 1.05;
	}
	public var defaultHUDCameraZoom:Float = FlxCamera.defaultZoom * 1.0;
	public var cameraBopIntensity:Float = Constants.DEFAULT_BOP_INTENSITY;
	public var hudCameraZoomIntensity:Float = 0.015 * 2.0;
	public var cameraZoomRate:Int = Constants.DEFAULT_ZOOM_RATE;

	// Discord RPC variables
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";
	private static var prevCamFollow:FlxObject;

	public var health:Float = Constants.HEALTH_STARTING;
	public var songScore:Int = 0;
	public var deathCounter:Int = 0;

	public var startTimestamp:Float = 0.0;
	public var playbackRate:Float = 1.0;

	public var generatedMusic:Bool = false;
	var overrideMusic:Bool = false;
	var criticalFailure:Bool = false;
	var initialized:Bool = false;

	public var paused:Bool = false;
	public var startingSong:Bool = false;
	public var startedCountdown:Bool = false;
	public var inCutscene:Bool = false;
	public var isPracticeMode:Bool = false;
	public var isBotPlayMode:Bool = false;
	public var isPlayerDying:Bool = false;
	public var isMinimalMode:Bool = false;
	public var isChartingMode(get, never):Bool;
	public var isSubState(get, never):Bool;
	function get_isSubState():Bool return this._parentState != null;
	function get_isChartingMode():Bool return this._parentState != null && Std.isOfType(this._parentState, ChartEditorState);
	public var canPause:Bool = true;
	public var needsReset:Bool = false;
	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camAlt:FlxCamera;
	public var forceZoom:Array<Float> = [0, 0, 0, 0];
	
	public static var iconRPC:String = "";
	public static var songLength:Float = 0;
	public var uiHUD:ClassHUD;

	public static var daPixelZoom:Float = 6;
	
	public var strumlines:FlxTypedGroup<Strumline>;
	var strumLine:FlxObject;
	public var comboGroup:FlxSpriteGroup;
	public static var keysArray(get, null):Array<Dynamic>;
	public var playerStrumline(get, never):Strumline;
	public var opponentStrumline(get, never):Strumline;

	function get_playerStrumline():Strumline
	{
		if(strumlines.members[0] == null) return null;
		return strumlines.members[0];
	}

	function get_opponentStrumline():Strumline
	{
		if(strumlines.members[1] == null) return null;
		return strumlines.members[1];
	}

	static function get_keysArray():Array<Dynamic>
    {
        return keysArray = [
			Init.copyKey(Init.gameControls.get('LEFT')[0]),
			Init.copyKey(Init.gameControls.get('DOWN')[0]),
			Init.copyKey(Init.gameControls.get('UP')[0]),
			Init.copyKey(Init.gameControls.get('RIGHT')[0])
		];
    }

	public function new(params:PlayStateParams)
	{
		super();

		// Validate parameters.
		if (params == null && lastParams == null)
		  throw 'PlayState constructor called with no available parameters.';
		else if (params == null)
		{
		  trace('WARNING: PlayState constructor called with no parameters. Reusing previous parameters.');
		  params = lastParams;
		}
		else
			lastParams = params;
	
		// Apply parameters.
		currentSong = params.targetSong;
		if (params.targetDifficulty != null) currentDifficulty = params.targetDifficulty;
		if (params.targetVariation != null) currentVariation = params.targetVariation;
		if (params.targetInstrumental != null) currentInstrumental = params.targetInstrumental;
		isPracticeMode = params.practiceMode ?? false;
		isBotPlayMode = params.botPlayMode ?? false;
		isMinimalMode = params.minimalMode ?? false;
		startTimestamp = params.startTimestamp ?? 0.0;
		playbackRate = params.playbackRate ?? 1.0;
		overrideMusic = params.overrideMusic ?? false;
		previousCameraFollowPoint = params.cameraFollowPoint;
	}

	function assertChartExists():Bool
	{
		if (currentSong == null || currentChart == null || currentChart.notes == null)
		{
			criticalFailure = true;
			var message:String = 'There was a critical error. Click OK to return to the main menu.';
			if (currentSong == null)
				message = 'There was a critical error loading this song\'s chart. Click OK to return to the main menu.';
			else if (currentDifficulty == null)
				message = 'There was a critical error selecting a difficulty for this song. Click OK to return to the main menu.';
			else if (currentChart == null)
				message = 'There was a critical error retrieving data for this song on "$currentDifficulty" difficulty with variation "$currentVariation". Click OK to return to the main menu.';
			else if (currentChart.notes == null)
				message = 'There was a critical error retrieving note data for this song on "$currentDifficulty" difficulty with variation "$currentVariation". Click OK to return to the main menu.';

			lime.app.Application.current.window.alert(message, 'Error loading PlayState');

			if (isSubState)
				this.close();
			else
				FlxG.switchState(() -> new MainMenuState());
			
			return false;
		}
		return true;
	}

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		if (!assertChartExists()) return;

		instance = this;
		Timings.callAccuracy();
		FlxG.fixedTimestep = false;

		this.persistentUpdate = this.persistentDraw = true;


		// stop any existing music tracks playing
		if (!overrideMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

		if (!overrideMusic && currentChart != null)
		{
			currentChart.cacheInst(currentInstrumental);
			currentChart.cacheVocals();
		}

		Conductor.instance.forceBPM(null);

		if (currentChart.offsets != null) Conductor.instance.instrumentalOffset = currentChart.offsets.getInstrumentalOffset(currentInstrumental);

		Conductor.instance.mapTimeChanges(currentChart.timeChanges);
		Conductor.instance.update((Conductor.instance.beatLengthMs * -5) + startTimestamp);

		initCameras();
		if (!isMinimalMode)
		{
			initStage();
			initCharacters();
		}
		else
			initMinimalMode();

		initStrumlines();
		initHUD();

		if (!Init.trueSettings.get('Controller Mode'))
			initialize();

		generateSong();
		resetCamera();

		startingSong = startedCountdown = true;
		
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		startCountdown();

		initialized = true;
		refresh();
	}
	
	public function resetCamera(?resetZoom:Bool = true, ?cancelTweens:Bool = true, ?snap:Bool = true):Void
	{
		if (cancelTweens) cancelAllCameraTweens();

		FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE);
		FlxG.camera.targetOffset.set();

		if (resetZoom) resetCameraZoom();	
		if (snap) FlxG.camera.focusOn(cameraFollowPoint.getPosition());
	}

	public function tweenCameraToPosition(?x:Float, ?y:Float, ?duration:Float, ?ease:Null<Float->Float>):Void
	{
		cameraFollowPoint.x = x;
		cameraFollowPoint.y = y;
		cameraFollowPoint.setPosition(x, y);
		tweenCameraToFollowPoint(duration, ease);
	}

	public function tweenCameraToFollowPoint(?duration:Float, ?ease:Null<Float->Float>):Void
	{
		cancelCameraFollowTween();

		if (duration == 0)
			resetCamera(false, false);
		else
		{
			FlxG.camera.target = null;
		
			var followPos:FlxPoint = cameraFollowPoint.getPosition() - FlxPoint.weak(FlxG.camera.width * 0.5, FlxG.camera.height * 0.5);
			cameraFollowTween = FlxTween.tween(FlxG.camera.scroll, {x: followPos.x, y: followPos.y}, duration,
			{
				ease: ease,
				onComplete: function(_) {
					resetCamera(false, false); // Re-enable camera following when the tween is complete.
				}
			});
		}
	}

	public function cancelCameraFollowTween()
	{
		if (cameraFollowTween != null) cameraFollowTween.cancel();
	}

	public function cancelCameraZoomTween()
	{
		if (cameraZoomTween != null) cameraZoomTween.cancel();
	}

	public function cancelAllCameraTweens()
	{
		cancelCameraFollowTween();
		cancelCameraZoomTween();
	}

	public function tweenCameraZoom(?zoom:Float, ?duration:Float, ?direct:Bool, ?ease:Null<Float->Float>):Void
	{
		cancelCameraZoomTween();
		var targetZoom = zoom * (direct ? FlxCamera.defaultZoom : stageZoom);

		if (duration == 0)
			currentCameraZoom = targetZoom;
		else
			cameraZoomTween = FlxTween.tween(this, {currentCameraZoom: targetZoom}, duration, {ease: ease});
	}

	function initHUD()
	{
		comboGroup = new FlxSpriteGroup();
		if (Init.trueSettings.get('Fixed Judgements'))
			comboGroup.camera = camHUD;

		// cache shit
		displayRating('sick', true, true);
		popUpCombo(true);
		//

		add(comboGroup);
		uiHUD = new ClassHUD();
		uiHUD.camera = camHUD;
		add(uiHUD);
	}

	function initStrumlines() 
	{
		var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(currentChart.noteStyle);
		if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();
		strumlines = new FlxTypedGroup<Strumline>();
		strumlines.camera = camHUD;
		add(strumlines);

		for(i in 0...2)
		{
			var strums:Strumline = new Strumline(noteStyle, Init.trueSettings.get('Downscroll'), false, i);
			strums.onNoteIncoming.add(onStrumlineNoteIncoming);
			var addtional:Float = 0;
			if(i == 0) addtional = (FlxG.width / 2);
			strums.x =  addtional + Constants.STRUMLINE_X_OFFSET; // Classic style
			strums.zIndex = 5000;
			strumlines.add(strums);
			strums.fadeInArrows();
		}

		if(Init.trueSettings.get('Centered Notefield'))
		{
			playerStrumline.x = FlxG.width / 2 - playerStrumline.width / 2;
			opponentStrumline.visible = false;
		}
	}

	function initCameras() {
		camGame = FlxG.camera; //Cam game can't use FunkinCamera cuz it will much fucked up
		camHUD = camAlt = new FunkinCamera();
		camHUD.bgColor = camAlt.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camAlt, false);

		cameraFollowPoint = new FlxObject(0, 0);
		if (previousCameraFollowPoint != null)
		{
			cameraFollowPoint.setPosition(previousCameraFollowPoint.x, previousCameraFollowPoint.y);
			previousCameraFollowPoint = null;
		}
		add(cameraFollowPoint);
	}

	function initMinimalMode():Void
	{
		// Create the green background.
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/base/menuDesat'));
		menuBG.color = 0xFF4CAF50;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
		add(menuBG);
	}

	function initStage():Void
	{
		stage = StageRegistry.instance.fetchEntry(currentStage);

		if (stage != null)
		{
			stage.revive(); 
		  ScriptEventDispatcher.callEvent(stage, new ScriptEvent(CREATE, false));
		  resetCameraZoom();
		  this.add(stage);
		  #if (debug || FORCE_DEBUG_VERSION)
		  FlxG.console.registerObject('stage', stage);
		  #end
		}
		else
		{
		  // lolol
		  lime.app.Application.current.window.alert('Unable to load stage ${currentStage}, is its data corrupted?.', 'Stage Error');
		}		
	}

	public function resetCameraZoom():Void
	{
		if (isMinimalMode) return;
		currentCameraZoom = stageZoom;
		FlxG.camera.zoom = currentCameraZoom;
		cameraBopMultiplier = 1.0;
	}

	function initCharacters():Void
	{
		if (currentSong == null || currentChart == null) trace('Song difficulty could not be loaded.');
		var currentCharacter:SongCharacterData = currentChart.characters;

		var girlfriend:BaseCharacter = BaseCharacter.fetchData(currentCharacter.girlfriend);

		if (girlfriend != null)
		  girlfriend.characterType = CharacterType.GF;
		else if (currentCharacter.girlfriend != '')
		  trace('WARNING: Could not load girlfriend character with ID ${currentCharacter.girlfriend}, skipping...');

		var dad:BaseCharacter = BaseCharacter.fetchData(currentCharacter.opponent);
		if (dad != null)
			dad.characterType = CharacterType.DAD;

		var boyfriend:BaseCharacter = BaseCharacter.fetchData(currentCharacter.player);
		if (boyfriend != null)
			boyfriend.characterType = CharacterType.BF;

		var otherChars:Array<BaseCharacter> = [];
		for(i in 0...currentCharacter.others.length)
		{
			var otherChar:BaseCharacter = BaseCharacter.fetchData(currentCharacter.others[i]);
			if (otherChar != null)
				otherChar.characterType = CharacterType.OTHER;
			otherChars.push(otherChar);
		}

		if (stage != null)
		{
			if (girlfriend != null)
				stage.addCharacter(girlfriend, GF);
		  
			if (boyfriend != null)
				stage.addCharacter(boyfriend, BF);
		  
			if (dad != null)
			{
				stage.addCharacter(dad, DAD);
				  // Camera starts at dad.
				cameraFollowPoint.setPosition(dad.cameraFocusPoint.x, dad.cameraFocusPoint.y);
			}

			for(i in 0...otherChars.length)
			{
				if (otherChars[i] != null)
					stage.addCharacter(dad, OTHER);
			}
		  
			// Rearrange by z-indexes.
			stage.refresh();			
		}
	}

	function regenNoteData(startTime:Float = 0):Void
	{
		Highscore.instance.tallies.combo = 0;

		var event:SongLoadScriptEvent = new SongLoadScriptEvent(currentChart.song.id, currentChart.difficulty, currentChart.notes.copy(), currentChart.events);
		dispatchEvent(event);

		if(event.eventCanceled) return;
		
		songEvents = event.events;
		SongEventRegistry.resetEvents(songEvents);

		var playerNoteData:Array<SongNoteData> = [];
		var opponentNoteData:Array<SongNoteData> = [];
		for (songNote in event.notes)
		{
			if (songNote == null) continue;

			var strumTime:Float = songNote.time;
			if (strumTime < startTime) continue;

			switch(songNote.getStrumlineIndex())
			{
				case 0:
					playerNoteData.push(songNote);
					Highscore.instance.tallies.totalNotes++;
				case 1:
					opponentNoteData.push(songNote);
			}
		}

		playerStrumline.applyNoteData(playerNoteData);
		opponentStrumline.applyNoteData(opponentNoteData);
	}

	function onStrumlineNoteIncoming(noteSprite:NoteSprite):Void
	{
		var event:NoteScriptEvent = new NoteScriptEvent(NOTE_INCOMING, noteSprite, 0, false);
		dispatchEvent(event);
	}

	function initialize():Void
	{
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
	}

	function deinitialize():Void
	{
        FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
	}

	override public function destroy()
	{
		if (!Init.trueSettings.get('Controller Mode'))
			deinitialize();
		performCleanup();
		super.destroy();
	}

	function performCleanup():Void
	{
		// If the camera is being tweened, stop it.
		cancelAllCameraTweens();
		cancelScrollSpeedTweens();

		// Dispatch the destroy event.
		dispatchEvent(new ScriptEvent(DESTROY, false));

		if (overrideMusic)
		{
			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null)
			{
			  vocals.pause();
			  remove(vocals);
			}
		}
		else
		{
			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			if (vocals != null)
			{
			  vocals.destroy();
			  remove(vocals);
			}
		}

		if (stage != null)
		{
			remove(stage);
			stage.kill();
			stage = null;
		}
		FunkinSprite.preparePurgeCache();
		FunkinSprite.purgeCache();
		GameOverSubState.reset();
		PauseSubState.reset();
		Countdown.reset();
		instance = null;
	}

	public var disableKeys:Bool = false;
	public var resetScore:Bool = true;
	override public function update(elapsed:Float)
	{
		if (criticalFailure) return;

		super.update(elapsed);

		if (health > Constants.HEALTH_MAX) health = Constants.HEALTH_MAX;
		if (health < Constants.HEALTH_MIN) health = Constants.HEALTH_MIN;

		if (subState == null &&cameraZoomRate > 0.0)
		{
			cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95); // Lerp bop multiplier back to 1.0x
			var zoomPlusBop = currentCameraZoom * cameraBopMultiplier; // Apply camera bop multiplier.
			FlxG.camera.zoom = zoomPlusBop; // Actually apply the zoom to the camera.
	  
			camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
		}

		if (needsReset)
		{
			if (!assertChartExists()) return;
			prevScrollTargets = [];
	  
			dispatchEvent(new ScriptEvent(SONG_RETRY));
			resetCamera();

			paused = isPlayerDying = false;
			persistentDraw = persistentUpdate = startingSong = true;

			if(resetScore)
			{
				songScore = 0;
				Highscore.instance.resetTallies();
				Timings.callAccuracy();
				Timings.updateAccuracy(0);
			}

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.time = startTimestamp - Conductor.instance.combinedOffset;
				FlxG.sound.music.pitch = playbackRate;
				FlxG.sound.music.pause();
			}

		    if (!overrideMusic)
			{
				if (vocals != null) vocals.stop();
				vocals = currentChart.buildVocals(currentInstrumental);
		
				if (vocals.members.length == 0) trace('WARNING: No vocals found for this song.');
			}
			vocals.pause();
			vocals.time = 0 - Conductor.instance.combinedOffset;

			if (FlxG.sound.music != null) FlxG.sound.music.volume = 1;
			vocals.volume = 1;
			vocals.playerVolume = 1;
			vocals.opponentVolume = 1;
			
			if (!isPlayerDying)
			{
				for(i in 0...strumlines.length)  strumlines.members[i].vwooshNotes();
			}
			for(i in 0...strumlines.length)  strumlines.members[i].clean();
			
			SongEventRegistry.precacheEvents(currentChart.events);

			regenNoteData();
			cameraBopIntensity = Constants.DEFAULT_BOP_INTENSITY;
			hudCameraZoomIntensity = (cameraBopIntensity - 1.0) * 2.0;
			cameraZoomRate = Constants.DEFAULT_ZOOM_RATE;

			health = Constants.HEALTH_STARTING;
			Countdown.performCountdown();
			needsReset = false;
		}

		if (Init.trueSettings.get('Controller Mode')) controllerInput();

		if (inCutscene)
		{
			if (VideoCutscene.isPlaying())
			{
				if (FlxG.keys.justPressed.ENTER && canPause && VideoCutscene.cutsceneType != CutsceneType.MIDSONG)
				{

					VideoCutscene.pause();

					var pauseSubState:FlxSubState = new PauseSubState({mode: Cutscene});
					persistentUpdate = false;
					persistentDraw = true;

					FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
					pauseSubState.camera = camAlt;
					openSubState(pauseSubState);
				}
			}
		}
		else
		{
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.instance.update(Conductor.instance.songPosition + elapsed * 1000, false);
					if (Conductor.instance.songPosition >= (startTimestamp + Conductor.instance.combinedOffset)) startSong();	
				}
			}
			else
			{
				Conductor.instance.formatOffset =  (Constants.EXT_SOUND == 'mp3') ? Constants.MP3_DELAY_MS : 0.0;
				Conductor.instance.update();
			}
			
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause && !disableKeys) pauseGame();

			// make sure you're not cheating lol
			if (!PlayStatePlaylist.isStoryMode)
			{
				// charting state (more on that later)
				if ((FlxG.keys.justPressed.SEVEN) && (!startingSong) && !disableKeys)
				{
					persistentUpdate = false;
					if (isChartingMode)
					{
						FlxG.sound.music?.pause();
						this.close();				
					}
					else
					{
						this.remove(stage);
						FlxG.switchState(() -> new ChartEditorState({targetSongId: currentSong.id}));
					}
				}

				if ((FlxG.keys.justPressed.EIGHT) && (!startingSong) && !disableKeys)
				{
					resetMusic();
					Main.switchState(new meta.state.editors.CharacterEditorState(currentChart.characters.opponent, true));
				}

				if (FlxG.keys.justPressed.FIVE)
				{
					persistentUpdate = false;
					persistentDraw = true;
					openSubState(new StageOffsetSubState());
				}

				if ((FlxG.keys.justPressed.SIX))
				{
					playerStrumline.botplay = !playerStrumline.botplay;
					uiHUD.autoplayMark.visible = playerStrumline.botplay;
					isBotPlayMode = !isBotPlayMode;
					currentSong.validScore = !currentSong.validScore; //idc if you cheat or not lol
				}
			}

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !PlayStatePlaylist.isStoryMode) health = Constants.HEALTH_MIN;

			if (health <= Constants.HEALTH_MIN && !isPracticeMode && !isPlayerDying)
			{
				persistentUpdate = persistentDraw = false;
				isPlayerDying = true;

				resetMusic();

				deathCounter += 1;

				dispatchEvent(new ScriptEvent(GAME_OVER));


				var deathPreTransitionDelay = boyfriend?.getDeathPreTransitionDelay() ?? 0.0;
				if (deathPreTransitionDelay > 0)
				{
				  new FlxTimer().start(deathPreTransitionDelay, function(_) {
					gameOver();
				  });
				}
				else
				{
				  // Transition immediately.
				  gameOver();
				}

				#if discord_rpc
				Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
				#end
			}

			noteCalls(elapsed);
		}
	}

	function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	function onKeyPress(event:KeyboardEvent):Void
	{
		var keyEvent:KeyboardInputScriptEvent = new KeyboardInputScriptEvent(KEY_DOWN, event);
		dispatchEvent(keyEvent);
		if(keyEvent.eventCanceled) return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if ((key >= 0)
			&& !playerStrumline.botplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			&& (FlxG.keys.enabled && !paused))
		{
			if (generatedMusic)
			{
				if(Init.trueSettings.get("Input System").toLowerCase() != 'v-slice')
					foreverInput(key);
				else
					vSliceInput(key);
			}
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void
	{
		var keyEvent:KeyboardInputScriptEvent = new KeyboardInputScriptEvent(KEY_UP, event);
		dispatchEvent(keyEvent);
		if(keyEvent.eventCanceled) return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused)
		{
			if (key >= 0)
				playerStrumline.playStatic(Strumline.DIRECTIONS[key]);
		}
	}

	function vSliceInput(key:Int)
	{
		var notesInRange:Array<NoteSprite> = playerStrumline.getNotesMayHit();
		var notesByDirection:Array<Array<NoteSprite>> = [[], [], [], []];
		for (note in notesInRange)
			notesByDirection[note.direction].push(note);

		var notesInDirection:Array<NoteSprite> = notesByDirection[Strumline.DIRECTIONS[key]];

		if (!playerStrumline.mayGhostTap() && notesInDirection.length == 0)
		{
			missNoteCheck(key);
			playerStrumline.playPress(Strumline.DIRECTIONS[key]);
		}
		else if (notesInDirection.length == 0)
		{
			playerStrumline.playPress(Strumline.DIRECTIONS[key]);
		}
		else
		{
			var targetNote:Null<NoteSprite> = notesInDirection.find((note) -> !note.lowPriority);
			if (targetNote == null) targetNote = notesInDirection[0];
			if (targetNote == null) return;

			goodNoteHit(targetNote, playerStrumline);

			notesInDirection.remove(targetNote);

			playerStrumline.playConfirm(Strumline.DIRECTIONS[key]);
		}
	}

	function foreverInput(key:Int)
	{
		var possibleNoteList:Array<NoteSprite> = [];
		var pressedNotes:Array<NoteSprite> = [];

		playerStrumline.notes.forEachAlive(function(note:NoteSprite) {
			if (note.direction == Strumline.DIRECTIONS[key] && note.mayHit && !note.hasBeenHit)
				possibleNoteList.push(note);
		});
		possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

		if (possibleNoteList.length > 0)
		{
			var eligable = true;
			var firstNote = true;

			for (coolNote in possibleNoteList)
			{
				for (noteDouble in pressedNotes)
				{
					if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
						firstNote = false;
					else
						eligable = false;
				}

				if (eligable)
				{
					goodNoteHit(coolNote, playerStrumline);
					playerStrumline.playConfirm(Strumline.DIRECTIONS[key]);
					pressedNotes.push(coolNote);
				}
			}
		}
		else if (!Init.trueSettings.get('Ghost Tapping'))
			missNoteCheck(key);

		playerStrumline.playPress(Strumline.DIRECTIONS[key]);
	}

	function controllerInput()
	{
		var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function processSongEvents():Void
	{
		if (songEvents != null && songEvents.length > 0)
		{
			var songEventsToActivate:Array<SongEventData> = SongEventRegistry.queryEvents(songEvents, Conductor.instance.songPosition);

			if (songEventsToActivate.length > 0)
			{
				trace('Found ${songEventsToActivate.length} event(s) to activate.');
				for (event in songEventsToActivate)
				{
				  // If an event is trying to play, but it's over 1 second old, skip it.
				  var eventAge:Float = Conductor.instance.songPosition - event.time;
				  if (eventAge > 1000)
				  {
					event.activated = true;
					continue;
				  };
		
				  var eventEvent:SongEventScriptEvent = new SongEventScriptEvent(event);
				  dispatchEvent(eventEvent);
				  // Calling event.cancelEvent() skips the event. Neat!
				  if (!eventEvent.eventCanceled)
				  {
					SongEventRegistry.handleEvent(event);
				  }
				}
			}
		}
	}

	function noteCalls(elapsed:Float)
	{

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			processNotes(elapsed);
			processSongEvents();
		}
	}

	function processNotes(elapsed:Float):Void
	{
		for(i in 0...strumlines.length)  
		{
			if(i == 0) continue;

			strumlines.members[i].notes.forEachAlive(function(note:NoteSprite)
			{
				var hitWindowStart = note.strumTime + Conductor.instance.inputOffset - Constants.HIT_WINDOW_MS;
				var hitWindowCenter = note.strumTime + Conductor.instance.inputOffset;
				var hitWindowEnd = note.strumTime + Conductor.instance.inputOffset + Constants.HIT_WINDOW_MS;
		
				if (Conductor.instance.songPosition > hitWindowEnd)
				{
					if (note.hasMissed || note.hasBeenHit) return;
		
					note.tooEarly = false;
					note.mayHit = false;
					note.hasMissed = true;
				
					if (note.holdNoteSprite != null)
					{
						note.holdNoteSprite.missedNote = true;
					}
				}
				else if (Conductor.instance.songPosition > hitWindowCenter)
				{
					if (note.hasBeenHit) return;
		
					var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
					dispatchEvent(event);
					if (event.eventCanceled) return;
		
					strumlines.members[i].hitNote(note);
					strumlines.members[i].playNoteSplash(note.noteData.getDirection());
					if (note.holdNoteSprite != null) strumlines.members[i].playNoteHoldCover(note.holdNoteSprite);
				}
				else if (Conductor.instance.songPosition > hitWindowStart)
				{
					if (note.hasBeenHit || note.hasMissed) return;
		
					note.tooEarly = false;
					note.mayHit = true;
					note.hasMissed = false;
					if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
				}
				else
				{
					note.tooEarly = true;
					note.mayHit = false;
					note.hasMissed = false;
					if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
				}
			});

			strumlines.members[i].holdNotes.forEachAlive(function(holdNote:SustainTrail){
				if (holdNote.missedNote && !holdNote.handledMiss) holdNote.handledMiss = true;

				if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
				{
					var event:SustainScriptEvent = new SustainScriptEvent(holdNote);
					dispatchEvent(event);
					if (event.eventCanceled) return;
				}
			});
		}

		playerStrumline.notes.forEachAlive(function(note:NoteSprite)
		{
            if (note.hasBeenHit)
			{
			  note.tooEarly = false;
			  note.mayHit = false;
			  note.hasMissed = false;
			  return;
			}
			
			var hitWindowStart = note.strumTime - Constants.HIT_WINDOW_MS;
			var hitWindowCenter = note.strumTime;
			var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;
	  
			if (Conductor.instance.songPosition > hitWindowEnd)
			{
			  if (note.hasMissed || note.hasBeenHit) return;
			  note.tooEarly = false;
			  note.mayHit = false;
			  note.hasMissed = true;
			  if (note.holdNoteSprite != null)
			  {
				note.holdNoteSprite.missedNote = true;
			  }
			}
			else if (playerStrumline.botplay && Conductor.instance.songPosition > hitWindowCenter)
			{
			  if (note.hasBeenHit) return;

			  var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
			  dispatchEvent(event);
			  if (event.eventCanceled) return;

			  var noteDiff:Float = Math.abs(note.strumTime - Conductor.instance.songPosition);
			  var isLate: Bool = note.strumTime < Conductor.instance.songPosition;
		  
			  // loop through all avaliable judgements
			  var foundRating:String = 'miss';
			  var lowestThreshold:Float = Math.POSITIVE_INFINITY;
			  for (myRating in Timings.judgementsMap.keys())
			  {
				  var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
				  if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
				  {
					  foundRating = myRating;
					  lowestThreshold = myThreshold;
				  }
			  }

			  playerStrumline.hitNote(note, (foundRating != 'good' || foundRating != 'sick'));

			  vocals.playerVolume = 1;

			  playerStrumline.playNoteSplash(note.noteData.getDirection());
			  if (note.holdNoteSprite != null) playerStrumline.playNoteHoldCover(note.holdNoteSprite);

			  increaseCombo(foundRating, note.noteData.data);
			  popUpScore(foundRating, isLate);
			  healthCall(Timings.judgementsMap.get(foundRating)[3]);
			  
			  Timings.notesHit++;
			  Highscore.instance.tallies.totalNotesHit++;
					
			}
			else if (Conductor.instance.songPosition > hitWindowStart)
			{
			  note.tooEarly = false;
			  note.mayHit = true;
			  note.hasMissed = false;
			  if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
			}
			else
			{
			  note.tooEarly = true;
			  note.mayHit = false;
			  note.hasMissed = false;
			  if (note.holdNoteSprite != null) note.holdNoteSprite.missedNote = false;
			}
	  
			// This becomes true when the note leaves the hit window.
			// It might still be on screen.
			if (note.hasMissed && !note.handledMiss)
			{
			  // Call an event to allow canceling the note miss.
			  // NOTE: This is what handles the character animations!
			  var event:NoteScriptEvent = new NoteScriptEvent(NOTE_MISS, note, -Constants.HEALTH_MISS_PENALTY, 0, true);
			  dispatchEvent(event);
	  
			  // Calling event.cancelEvent() skips all the other logic! Neat!
			  if (event.eventCanceled) return;
	  
			  // Skip handling the miss in botplay!
			  if (!playerStrumline.botplay) noteMiss(note);
			  note.handledMiss = true;
			}
		});

		playerStrumline.holdNotes.forEachAlive(function(holdNote:SustainTrail)
		{
			// While the hold note is being hit, and there is length on the hold note...
			if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
			{
				Timings.updateAccuracy(100, true, playerStrumline.holdNotes.length);
				health += Constants.HEALTH_HOLD_BONUS_PER_SECOND * elapsed;
				songScore += Std.int(Constants.SCORE_HOLD_BONUS_PER_SECOND * elapsed);
	  
			  // Make sure the player keeps singing while the note is held by the bot.
			  var event:SustainScriptEvent = new SustainScriptEvent(holdNote);
			  dispatchEvent(event);
			  if (event.eventCanceled) return;
			}
	  
			if (holdNote.missedNote && !holdNote.handledMiss) holdNote.handledMiss = true;
		});
	}

	function handleSkippedNotes():Void
	{
		for(i in 0...strumlines.length) strumlines.members[i].handleSkippedNotes();  
	}

	function goodNoteHit(note:NoteSprite, strumline:Strumline, ?canDisplayJudgement:Bool = true):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.instance.songPosition);
		var isLate: Bool = note.strumTime < Conductor.instance.songPosition;
	
		// loop through all avaliable judgements
		var foundRating:String = 'miss';
		var lowestThreshold:Float = Math.POSITIVE_INFINITY;
		for (myRating in Timings.judgementsMap.keys())
		{
			var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
			if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
			{
				foundRating = myRating;
				lowestThreshold = myThreshold;
			}
		}
		
		strumline.hitNote(note, (foundRating != 'good' || foundRating != 'sick'));
		strumline.playNoteSplash(note.noteData.getDirection());
		if (note.holdNoteSprite != null) strumline.playNoteHoldCover(note.holdNoteSprite);
		vocals.playerVolume = 1;
		//idk how to do this lol
		var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
		dispatchEvent(event);

		if (event.eventCanceled) return;

		Highscore.instance.tallies.totalNotesHit++;
		healthCall(Timings.judgementsMap.get(foundRating)[3]);
		Timings.notesHit++;
		
		if (canDisplayJudgement)
		{
			increaseCombo(foundRating, note.noteData.data);
			popUpScore(foundRating, isLate);
		}
	}

	function noteMiss(daNote:NoteSprite, ?popMiss:Bool = true):Void 
	{
		decreaseCombo(popMiss);

		vocals.playerVolume = 0;
		Timings.updateAccuracy(0);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function missNoteCheck(direction:NoteDirection, popMiss:Bool = false, lockMiss:Bool = false)
	{
		var event:GhostMissNoteScriptEvent = new GhostMissNoteScriptEvent(direction, // Direction missed in.
			true, // Whether there was a note you could have hit.
			- 1 * Constants.HEALTH_MISS_PENALTY, // How much health to add (negative).
			- 10 // Amount of score to add (negative).
		);
		dispatchEvent(event);

		if (event.eventCanceled) return;

		if (event.playSound)
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
		decreaseCombo(popMiss);
	}

	function gameOver():Void
	{
		songScore = 0;
		health = Constants.HEALTH_STARTING;

		var gameOverSubState = new GameOverSubState(
		{
			isChartingMode: isChartingMode,
			transparent: persistentDraw
		});
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		openSubState(gameOverSubState);
	}

	public function pauseGame()
	{
		var event = new PauseScriptEvent(FlxG.random.bool(1 / 1000));

		dispatchEvent(event);
  
		if (event.eventCanceled) return;
		// pause discord rpc
		updateRPC(true);

		// pause game


		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// open pause substate
		var pauseSubState:FlxSubState = new PauseSubState({mode: isChartingMode ? Charting : Standard});
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		pauseSubState.camera = camHUD;
		openSubState(pauseSubState);
	}

	public override function dispatchEvent(event:ScriptEvent):Void
	{
		super.dispatchEvent(event);

		ScriptEventDispatcher.callEvent(stage, event);
		if (stage != null) stage.dispatchToCharacters(event);
		NoteKindManager.callEvent(event);
		ScriptEventDispatcher.callEvent(currentSong, event);
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		if (canPause && !paused && !Init.trueSettings.get('Auto Pause'))
			pauseGame();
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if discord_rpc
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (instance.health > Constants.HEALTH_MIN && !instance.paused && FlxG.autoPause)
		{
			if (Conductor.instance.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.instance.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, isLate: Bool)
	{
		// set up the rating
		var score:Int = 50;
		displayRating(baseRating, isLate);
		switch (baseRating)
		{
			case 'sick':
				Highscore.instance.tallies.sick += 1;
			case 'good':
				Highscore.instance.tallies.good += 1;
			case 'bad':
				Highscore.instance.tallies.bad += 1;
			case 'shit':
				Highscore.instance.tallies.shit += 1;
		}

		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		songScore += score;

		popUpCombo();
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		// painful if statement
		if (((Highscore.instance.tallies.combo > 5) || (Highscore.instance.tallies.combo < 0)) && (gf != null && gf.animOffsets.exists('sad')))
			gf.playAnim('sad');

		if (Highscore.instance.tallies.combo > 0)
			Highscore.instance.tallies.combo = 0; // bitch lmao
		else
			Highscore.instance.tallies.combo--;

		// misses
		songScore -= 10;
		Highscore.instance.tallies.missed++;

		// display negative combo
		if (popMiss)
		{
			// doesnt matter miss ratings dont have timings
			displayRating("miss", true);
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}
		popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction:NoteDirection = LEFT)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (Highscore.instance.tallies.combo < 0)
					Highscore.instance.tallies.combo = 0;
				Highscore.instance.tallies.combo += 1;

				if (Highscore.instance.tallies.combo > Highscore.instance.tallies.maxCombo) Highscore.instance.tallies.maxCombo = Highscore.instance.tallies.combo;
			}
			else
				missNoteCheck(direction, false, true);
		}
	}

	public function displayRating(daRating:String, isLate: Bool, ?cache:Bool = false)
	{
		final timing =  isLate ? "late" : "early";
		var rating = ForeverAssets.generateRating('$daRating', false, timing, currentChart.noteStyle);
		if (cache) rating.alpha = 0.000001;
		comboGroup.add(rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.instance.stepLengthMs * 0.00125
			});
		}
		else
		{
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {
				type: FlxTweenType.BACKWARD,
				ease: FlxEase.circOut
			});
			FlxTween.tween(rating.scale, {x: 0, y: 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.instance.stepLengthMs * 0.00125
			});
		}
		// */

		if (!cache)
		{
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				// bound to camera
				rating.camera = camHUD;
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false)
	{
		var comboString:String = Std.string(Highscore.instance.tallies.combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (Highscore.instance.tallies.combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");

		for (scoreInt in 0...stringArray.length)
		{
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], false, currentChart.noteStyle, negative, createdColor, scoreInt);
			if (cache) numScore.alpha = 0.000001;
			comboGroup.add(numScore);

			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements'))
			{
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.instance.stepLengthMs * 0.002
				});
			}
			else
			{
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= ((comboString.length - 1) * 22);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {
					type: FlxTweenType.BACKWARD,
					ease: FlxEase.circOut,
				});
				FlxTween.tween(numScore.scale, {x: 0, y: 0}, 0.1, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.instance.stepLengthMs * 0.002
				});
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements'))
				numScore.y += 50;
			numScore.x += 100;
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void
	{
		startingSong = false;
		previousFrameTime = FlxG.game.ticks;

		
		if (!overrideMusic && !paused && currentChart != null) currentChart.playInst(1.0, currentInstrumental, false);

		if (FlxG.sound.music == null)
		{
			FlxG.log.error('PlayState failed to initialize instrumental!');
			return;
		}

		FlxG.sound.music.onComplete = endSong;
		FlxG.sound.music.play(true, Math.max(0, startTimestamp - Conductor.instance.combinedOffset));
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.volume = 1;
		if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();

		vocals.play();
		vocals.volume = 1;
		vocals.pitch = playbackRate;
		vocals.time = FlxG.sound.music.time;
		resyncVocals();

		camAlt.visible = true;

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		updateRPC(false);
		#end

		if (startTimestamp > 0) handleSkippedNotes();


		dispatchEvent(new ScriptEvent(SONG_START));
	}

	private function generateSong():Void
	{
		if (currentChart == null)   trace('Song difficulty could not be loaded.');

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = currentSong.id + ' - ' + currentDifficulty.toUpperCase();

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);

		if (!overrideMusic)
		{
			if (vocals != null) vocals.stop();
			vocals = currentChart.buildVocals(currentInstrumental);

			if (vocals.members.length == 0) trace('WARNING: No vocals found for this song.');
		}
		add(vocals);

		SongEventRegistry.precacheEvents(currentChart.events);
		
		regenNoteData();
		ScriptEventDispatcher.callEvent(currentSong, new ScriptEvent(CREATE, false));
		generatedMusic = true;
	}

	var prevScrollTargets:Array<Dynamic> = []; // used to snap scroll speed when things go unruely
	public function tweenScrollSpeed(?speed:Float, ?duration:Float, ?ease:Null<Float->Float>, current:Int):Void
	{
		cancelScrollSpeedTweens();

		// Snap to previous event value to prevent the tween breaking when another event cancels the previous tween.
		for (i in prevScrollTargets)
		{
		  var value:Float = i[0];
		  strumlines.members[i[1]].scrollSpeed = value;
		}
	
		// for next event, clean array.
		prevScrollTargets = [];
	
		var value:Float = speed;
		var strum:Strumline = strumlines.members[current];
		if (duration == 0)
		{
		  strum.scrollSpeed = value;
		}
		else
		{
		  scrollSpeedTweens.push(FlxTween.tween(strum,
			{
			  'scrollSpeed': value
			}, duration, {ease: ease}));
		}
		// make sure charts dont break if the charter is dumb and stupid
		prevScrollTargets.push([value, current]);
	}

	public function cancelScrollSpeedTweens()
	{
		for (tween in scrollSpeedTweens)
		{
			if (tween != null) tween.cancel();
		}
		scrollSpeedTweens = [];
	}

	function resyncVocals():Void
	{
		if (vocals == null) return;

		// Skip this if the music is paused (GameOver, Pause menu, start-of-song offset, etc.)
		if (!(FlxG.sound.music?.playing ?? false)) return;
	
		var timeToPlayAt:Float = Math.min(FlxG.sound.music.length, Math.max(0, Conductor.instance.songPosition - Conductor.instance.combinedOffset));
		trace('Resyncing vocals to ${timeToPlayAt}');
		FlxG.sound.music.pause();
		vocals.pause();
	
		FlxG.sound.music.time = timeToPlayAt;
		FlxG.sound.music.play(false, timeToPlayAt);
	
		vocals.time = timeToPlayAt;
		vocals.play(false, timeToPlayAt);
	}

	override function stepHit()
	{
		super.stepHit();

		if (criticalFailure || !initialized) return;

		if (FlxG.sound.music != null)
		{
			var correctSync:Float = Math.min(FlxG.sound.music.length, Math.max(0, Conductor.instance.songPosition - Conductor.instance.combinedOffset));
			var playerVoicesError:Float = 0;
			var opponentVoicesError:Float = 0;

			if (vocals != null)
			{
				@:privateAccess // todo: maybe make the groups public :thinking:
				{
					vocals.playerVoices.forEachAlive(function(voice:FlxSound) {
					  var currentRawVoiceTime:Float = voice.time + vocals.playerVoicesOffset;
					  if (Math.abs(currentRawVoiceTime - correctSync) > Math.abs(playerVoicesError)) playerVoicesError = currentRawVoiceTime - correctSync;
					});
		  
					vocals.opponentVoices.forEachAlive(function(voice:FlxSound) {
					  var currentRawVoiceTime:Float = voice.time + vocals.opponentVoicesOffset;
					  if (Math.abs(currentRawVoiceTime - correctSync) > Math.abs(opponentVoicesError)) opponentVoicesError = currentRawVoiceTime - correctSync;
					});
				}
			}

			if (!startingSong && (Math.abs(FlxG.sound.music.time - correctSync) > 5 || Math.abs(playerVoicesError) > 5 || Math.abs(opponentVoicesError) > 5))
				resyncVocals();
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (criticalFailure || !initialized) return;


		if ((!Init.trueSettings.get('Reduced Movements'))  && FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom)
			&& cameraZoomRate > 0
			&& Conductor.instance.currentBeat % cameraZoomRate == 0)
		{
			cameraBopMultiplier = cameraBopIntensity;
			camHUD.zoom += hudCameraZoomIntensity * defaultHUDCameraZoom;
		}
		
		uiHUD.beatHit();
	}

	public static function isNull():Bool
	{
		if (instance == null || instance.stage == null || instance.isMinimalMode) return true;
		return false;
	}

	public static function pauseTweens(resume:Bool):Void 
	{
		FlxTween.globalManager.forEach(function(t) t.active = !resume);
		FlxTimer.globalManager.forEach(function(t) t.active = !resume);
	}

	public override function openSubState(subState:FlxSubState):Void
	{
		var shouldPause = (Std.isOfType(subState, PauseSubState) || Std.isOfType(subState, GameOverSubState));

		if (shouldPause)
		{
			paused = true;

			if (FlxG.sound.music != null && FlxG.sound.music.playing) FlxG.sound.music.pause();
			if (vocals != null && vocals != null) vocals.pause();

			FlxG.camera.followLerp = 0;

			pauseTweens(true);

			updateRPC(true);
		}
		super.openSubState(subState);
	}

	override function closeSubState()
	{
		if (Std.isOfType(subState, PauseSubState))
		{
			var event:ScriptEvent = new ScriptEvent(RESUME, true);

			dispatchEvent(event);
	  
			if (event.eventCanceled) return;

			pauseTweens(false);

			if (paused)
			{
				FlxG.sound.music.play();
				paused = false;
			}

			if (FlxG.sound.music != null && !startingSong && !inCutscene) resyncVocals();

			FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE;

			updateRPC(false);
		}

		super.closeSubState();
	}

	public function endSong():Void
	{
		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		canPause = false;

		var event = new ScriptEvent(SONG_END, true);
		dispatchEvent(event);
		if (event.eventCanceled) return;

		deathCounter = 0;

		var suffixedDifficulty = (currentVariation != Constants.DEFAULT_VARIATION && currentVariation != 'erect') ? '$currentDifficulty-${currentVariation}' : currentDifficulty;
		var isNewHighscore = false;
		var prevScoreData:Null<SaveScoreData> = Highscore.instance.getSongScore(currentSong.id, suffixedDifficulty);
		if (currentSong != null && currentSong.validScore)
		{
			var data = {
				score: songScore,
				tallies: 
				{
					sick: Highscore.instance.tallies.sick,
					good: Highscore.instance.tallies.good,
					bad: Highscore.instance.tallies.bad,
					shit: Highscore.instance.tallies.shit,
					missed: Highscore.instance.tallies.missed,
					combo: Highscore.instance.tallies.combo,
					maxCombo: Highscore.instance.tallies.maxCombo,
					totalNotesHit: Highscore.instance.tallies.totalNotesHit,
					totalNotes: Highscore.instance.tallies.totalNotes,
				}
			};
			Highscore.instance.talliesLevel = Highscore.instance.combineTallies(Highscore.instance.tallies, Highscore.instance.talliesLevel);

			if (!isPracticeMode && !isBotPlayMode)
			{
				isNewHighscore = Highscore.instance.isSongHighScore(currentSong.id, suffixedDifficulty, data);
				Highscore.instance.applySongRank(currentSong.id, suffixedDifficulty, data);
			}
		}

		if (PlayStatePlaylist.isStoryMode)
		{
			isNewHighscore = false;
			PlayStatePlaylist.campaignScore += songScore;
			var targetSongId:String = PlayStatePlaylist.playlistSongIds.shift();

			if (targetSongId == null)
			{
				ForeverTools.resetMenuMusic();
				var data = {
					score: PlayStatePlaylist.campaignScore,
					tallies:
					{
						sick: 0,
						good: 0,
						bad: 0,
						shit: 0,
						missed: 0,
						combo: 0,
						maxCombo: 0,
						totalNotesHit: 0,
						totalNotes: 0						
					}
				};
				if (Highscore.instance.isLevelHighScore(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignDifficulty, data))
				{
					Highscore.instance.setLevelScore(PlayStatePlaylist.campaignId, PlayStatePlaylist.campaignDifficulty, data);
					isNewHighscore = true;
				}

				if (isSubState)
					this.close();
				else
					zoomIntoResultsScreen(isNewHighscore, prevScoreData);
			}
			else
			{
				FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
				if (FlxG.sound.music != null) FlxG.sound.music.stop();
				vocals.stop();
		
				var targetSong:Song = SongRegistry.instance.fetchEntry(targetSongId);
				var targetVariation:String = currentVariation;
				if (!targetSong.hasDifficulty(PlayStatePlaylist.campaignDifficulty, currentVariation))
				{
					targetVariation = targetSong.getFirstValidVariation(PlayStatePlaylist.campaignDifficulty) ?? Constants.DEFAULT_VARIATION;
				}

				LoadingSubState.loadPlayState({
					targetSong: targetSong,
					targetDifficulty: PlayStatePlaylist.campaignDifficulty,
					targetVariation: targetVariation,
					cameraFollowPoint: cameraFollowPoint.getPosition()
				});
			}
		}
		else
		{
			if (isSubState)
				this.close();
			else
				zoomIntoResultsScreen(isNewHighscore, prevScoreData);
		}
	}

	function zoomIntoResultsScreen(isNewHighscore:Bool, ?prevScoreData:SaveScoreData):Void
	{
		cameraZoomRate = 0;	
		cancelAllCameraTweens();
		cancelScrollSpeedTweens();

		var targetDad:Bool = dad != null && dad.id == 'gf';
		var targetBF:Bool = gf == null && !targetDad;

		if (targetBF)
			FlxG.camera.follow(boyfriend, null, 0.05);
		else if (targetDad)
			FlxG.camera.follow(dad, null, 0.05);
		else
			FlxG.camera.follow(gf, null, 0.05);

		FlxG.camera.targetOffset.y -= 350;
		FlxG.camera.targetOffset.x += 20;
	
		// Replace zoom animation with a fade out for now.
		FlxG.camera.fade(FlxColor.BLACK, 0.6);
		var talliesToUse:Tallies = PlayStatePlaylist.isStoryMode ? Highscore.instance.talliesLevel : Highscore.instance.tallies;
		var scoreData = {
			score: PlayStatePlaylist.isStoryMode ? PlayStatePlaylist.campaignScore : songScore,
			tallies: {
				sick: talliesToUse.sick,
				good: talliesToUse.good,
				bad: talliesToUse.bad,
				shit: talliesToUse.shit,
				missed: talliesToUse.missed,
				combo: talliesToUse.combo,
				maxCombo: talliesToUse.maxCombo,
				totalNotesHit: talliesToUse.totalNotesHit,
				totalNotes: talliesToUse.totalNotes,
			}
		}

		var rank:ScoringRank = (currentSong != null && currentSong.validScore) ? Scoring.calculateRank(scoreData) : SHIT;

		FlxTween.tween(camHUD, {alpha: 0}, 0.6,{onComplete: function(_) {

			if(PlayStatePlaylist.isStoryMode && (Init.trueSettings.get('Skip Result') == 'story only' || Init.trueSettings.get('Skip Result') == 'always'))
				FlxG.switchState(new StoryMenuState());
			else if(Init.trueSettings.get('Skip Result') == 'freeplay only' || Init.trueSettings.get('Skip Result') == 'always')
			{
				//if they skip result screen give them chance what you got lmao
				if (rank > Scoring.calculateRank(prevScoreData))
				{
					FlxG.switchState(FreeplayState.build({character: PlayerRegistry.instance.getCharacterOwnerId(currentChart.characters.player) ?? "bf",
					fromResults: {
						oldRank: Scoring.calculateRank(prevScoreData),
						newRank: rank,
						songId: currentChart.song.id,
						difficultyId: currentDifficulty,
						playRankAnim: true
					}}));
				}
				else
				{
					FlxG.switchState(FreeplayState.build());
				}

				//Idk Result Score after you put score it ok then :/
				PlayState.instance.songScore = 0;
				Highscore.instance.resetTallies();
				Timings.callAccuracy();
				Timings.updateAccuracy(0);				
			}
			else //this is never then lol
				moveToResultsScreen(isNewHighscore, prevScoreData);
		}});

		new FlxTimer().start(0.8, function(_) {
			if (targetBF)
				boyfriend.playAnim('hey', true);
			else if (targetDad)
				dad.playAnim('cheer', true);
			else
				gf.playAnim('cheer', true);
		});
	}

	function moveToResultsScreen(isNewHighscore:Bool, ?prevScoreData:SaveScoreData):Void
	{
		persistentUpdate = false;
		vocals.stop();
		camHUD.alpha = 1;
	
		var talliesToUse:Tallies = PlayStatePlaylist.isStoryMode ? Highscore.instance.talliesLevel : Highscore.instance.tallies;

		var res:ResultSubState = new ResultSubState({
			storyMode: PlayStatePlaylist.isStoryMode,
			songId: currentChart.song.id,
			difficultyId: currentDifficulty,
			characterId: currentChart.characters.player,
			title: PlayStatePlaylist.isStoryMode ? ('${PlayStatePlaylist.campaignTitle}') : ('${currentChart.songName} by ${currentChart.songArtist}'),
			prevScoreData: prevScoreData,
			scoreData: {
				score: PlayStatePlaylist.isStoryMode ? PlayStatePlaylist.campaignScore : songScore,
				tallies: {
					sick: talliesToUse.sick,
					good: talliesToUse.good,
					bad: talliesToUse.bad,
					shit: talliesToUse.shit,
					missed: talliesToUse.missed,
					combo: talliesToUse.combo,
					maxCombo: talliesToUse.maxCombo,
					totalNotesHit: talliesToUse.totalNotesHit,
					totalNotes: talliesToUse.totalNotes,
				}
			},
			isNewHighscore: isNewHighscore,
			validScore: currentSong != null ? currentSong.validScore : false
		});
		this.persistentDraw = false;
		openSubState(res);
	}

	public static function skipCutscenes():Bool
	{
		// pretty messy but an if statement is messier
		if (Init.trueSettings.get('Skip Text') != null && Std.isOfType(Init.trueSettings.get('Skip Text'), String))
		{
			switch (cast(Init.trueSettings.get('Skip Text'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
						return !PlayStatePlaylist.isStoryMode;
				default:
					return true;
			}
		}
		return false;
	}

	public static function skipResultScreen():Bool
	{
		if (Init.trueSettings.get('Skip Result') != null && Std.isOfType(Init.trueSettings.get('Skip Result'), String))
		{
			switch (cast(Init.trueSettings.get('Skip Result'), String))
			{
				case 'never':
					return false;
				case 'freeplay only':
					return !PlayStatePlaylist.isStoryMode;
				default:
					return true;
			}
		}
		return false;
	}

	public static var swagCounter:Int = 0;

	public function startCountdown():Void
	{
		var result:Bool = Countdown.performCountdown();
		if (!result) return;

		inCutscene = false;
		camAlt.visible = false;
		camHUD.visible = true;
	}

	public static function resetMusic()
	{
		// simply stated, resets the playstate's music for other states and substates
		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		if (instance.vocals != null)
			instance.vocals.stop();
	}

	public static function pauseMusic()
	{
		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		if (instance.vocals != null)
			instance.vocals.pause();
	}
}
