package meta.state;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameObjects.*;
import gameObjects.userInterface.*;
import gameObjects.userInterface.notes.*;
import meta.*;
import meta.data.*;
import meta.data.Song.SwagSong;
import meta.data.Song.SwagEvent;
import meta.state.charting.*;
import meta.state.menus.*;
import meta.subState.*;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.io.File;

using StringTools;

#if desktop
import meta.data.dependency.Discord;
#end

class PlayState extends MusicBeatState
{
	public static var instance:PlayState;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:String = "";
	public static var storyPlaylist:Array<String> = [];
	public static var curDifficulty:String = 'normal';
	public static var vocals:FlxSound;
	public static var vocalsDad:FlxSound;
	public var swagSong:Song;

	public static var campaignScore:Int = 0;

	public var dad(get, never):BaseCharacter;
	public var gf(get, never):BaseCharacter;
	public var boyfriend(get, never):BaseCharacter;
	public var stage:Stage = null;
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

	public static var assetModifier:String = 'base';
	public static var changeableSkin:String = 'default';
	
	public var eventList:Array<SwagEvent> = [];
	private var ratingArray:Array<String> = [];
	private var allSicks:Bool = true;

	// if you ever wanna add more keys
	public static var numberOfKeys:Int = 4;

	public var cameraFollowPoint:FlxObject;
	public var cameraFollowTween:FlxTween;
	public var cameraZoomTween:FlxTween;
	public var scrollSpeedTweens:Array<FlxTween> = [];
	
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

	private var curSong:String = "";
	private var gfSpeed:Int = 1;

	public var health:Float = Constants.HEALTH_STARTING;
	public var songScore:Int = 0;
	public var deathCounter:Int = 0;
	public var combo:Int = 0;
	public var misses:Int = 0;

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
	public static var isChartingMode:Bool = false;
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
	public static var determinedChartType:String = "";

	// strumlines
	public var cpuStrums:Strumline;
	public var plrStrums:Strumline;

	public var comboGroup:FlxSpriteGroup;
	public var keysArray(get, null):Array<Dynamic>;

	function get_keysArray():Array<Dynamic>
    {
        return keysArray = [
			Init.copyKey(Init.gameControls.get('LEFT')[0]),
			Init.copyKey(Init.gameControls.get('DOWN')[0]),
			Init.copyKey(Init.gameControls.get('UP')[0]),
			Init.copyKey(Init.gameControls.get('RIGHT')[0])
		];
    }
	function resetStatics()
	{
		// reset any values and variables that are static
		assetModifier = 'base';
		changeableSkin = 'default';
		PlayState.SONG.validScore = true;
	}

	// at the beginning of the playstate
	override public function create()
	{
		super.create();

		instance = this;
		resetStatics();
		Timings.callAccuracy();
		FlxG.fixedTimestep = false;

		// default song
		SONG = Song.checkSong(SONG, null);

		Conductor.mapBPMChanges(SONG);
		Conductor.bpm = SONG.bpm;

		determinedChartType = "FNF";

		curStage = "stage";
		if (SONG.stage != null)
			curStage = SONG.stage;

		if (SONG.assetModifier != null && SONG.assetModifier.length > 1)
			assetModifier = SONG.assetModifier;

		changeableSkin = Init.trueSettings.get("UI Skin");
		if ((curStage.startsWith("school")) && ((determinedChartType == "FNF")))
			assetModifier = 'pixel';

		// stop any existing music tracks playing
		if (!overrideMusic && FlxG.sound.music != null) FlxG.sound.music.stop();

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

		Conductor.songPosition = -(Conductor.crochet * 4);

		generateSong();

		startingSong = startedCountdown = true;

		resetCamera();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		startCountdown();

		initialized = true;

		if(eventList.length < 1) checkEventNote();
	}

	public function resetCamera(?resetZoom:Bool = true, ?cancelTweens:Bool = true):Void
	{
		if (cancelTweens) cancelAllCameraTweens();

		FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE);
		FlxG.camera.targetOffset.set();

		if (resetZoom) resetCameraZoom();	
		FlxG.camera.focusOn(cameraFollowPoint.getPosition());
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
		var noteStyle:NoteStyle = NoteStyleRegistry.instance.fetchEntry(assetModifier);
		if (noteStyle == null) noteStyle = NoteStyleRegistry.instance.fetchDefault();

		plrStrums = new Strumline(noteStyle, Init.trueSettings.get('Downscroll'), false, 0);
		plrStrums.onNoteIncoming.add(onStrumlineNoteIncoming);
		plrStrums.x = FlxG.width / 2 + Constants.STRUMLINE_X_OFFSET; // Classic style
		plrStrums.cameras = [camHUD];
		plrStrums.zIndex = 5000;
		add(plrStrums);

		cpuStrums = new Strumline(noteStyle, Init.trueSettings.get('Downscroll'), true, 1);
		cpuStrums.onNoteIncoming.add(onStrumlineNoteIncoming);
		cpuStrums.x = Constants.STRUMLINE_X_OFFSET;
		cpuStrums.cameras = [camHUD];
		cpuStrums.zIndex = 5000;
		add(cpuStrums);

		plrStrums.fadeInArrows();
		cpuStrums.fadeInArrows();
	}

	function initCameras() {
		camGame = new FunkinCamera();
		camHUD = camAlt = new FunkinCamera();
		camHUD.bgColor = camAlt.bgColor = 0x00000000;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camAlt, false);

		cameraFollowPoint = new FlxObject(0, 0);
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
		stage = StageRegistry.instance.fetchEntry(curStage);

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
		  lime.app.Application.current.window.alert('Unable to load stage ${curStage}, is its data corrupted?.', 'Stage Error');
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
		var girlfriend:BaseCharacter = BaseCharacter.fetchData(SONG.characters[2]);

		if (girlfriend != null)
		  girlfriend.characterType = CharacterType.GF;
		else if (SONG.characters[2] != '')
		  trace('WARNING: Could not load girlfriend character with ID ${SONG.characters[2]}, skipping...');

		var dad:BaseCharacter = BaseCharacter.fetchData(SONG.characters[1]);
		if (dad != null)
			dad.characterType = CharacterType.DAD;

		var boyfriend:BaseCharacter = BaseCharacter.fetchData(SONG.characters[0]);
		if (boyfriend != null)
			boyfriend.characterType = CharacterType.BF;

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
		  
			// Rearrange by z-indexes.
			stage.refresh();			
		}
	}

	//yeah do Leagcy FNF Chart (scary)
	function regenNoteData():Void
	{
		var playerNoteData:Array<NoteJson> = [];
		var opponentNoteData:Array<NoteJson> = [];
		for (section in SONG.notes)
		{
			if(section.sectionNotes != null && section.sectionNotes.length > 0)
			{
				for (songNote in section.sectionNotes)
				{
					var gottaHitNote:Bool = section.mustHitSection;
					if (songNote.data > 3) gottaHitNote = !section.mustHitSection;

					if(gottaHitNote)
						playerNoteData.push(songNote);
					else
						opponentNoteData.push(songNote);
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
					eventList.push(subEvent);
					eventList.sort(sortByShit);
				}
			}
		}

		plrStrums.applyNoteData(playerNoteData);
		cpuStrums.applyNoteData(opponentNoteData);
	}

	function onStrumlineNoteIncoming(noteSprite:NoteSprite):Void
	{
		var event:NoteScriptEvent = new NoteScriptEvent(NOTE_INCOMING, noteSprite, 0, false);

		dispatchEvent(event);
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
			for(i in [vocals, vocalsDad])
			{
				if(i != null)
				{
					i.pause();
					remove(i);
				}
			}
		}
		else
		{   
			if (FlxG.sound.music != null) FlxG.sound.music.pause();
			for(i in [vocals, vocalsDad])
			{
				if(i != null)
				{
					i.destroy();
					remove(i);
				}
			}
		}

		if (stage != null)
		{
			remove(stage);
			stage.kill();
			stage = null;
		}
		
		GameOverSubState.reset();
		PauseSubState.reset();
		Countdown.reset();
		
		// Clear the static reference to this state.
		instance = null;
	}

	override function debug_refreshModules():Void
	{
		criticalFailure = true;

		if (!overrideMusic)
		{
			// Stop the instrumental.
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.destroy();
				FlxG.sound.music = null;
			}
		
			// Stop the vocals.
			for(i in [vocals, vocalsDad])
			{
				if (i != null && i.exists)
				{
					i.destroy();
					i = null;
				}
			}
		}
		else
		{
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			for(i in [vocals, vocalsDad])
			{
				if (i != null && i.exists) i.stop();
			}
			if (vocals != null && vocals.exists) vocals.stop();
		}
		
		super.debug_refreshModules();		
		ScriptEventDispatcher.callEvent(SongHandler.getSong(PlayState.SONG.song.toLowerCase()), new ScriptEvent(CREATE, false));
	}

	var lastBar:Int = 0;
	public var disableKeys:Bool = false;
	
	override public function update(elapsed:Float)
	{
		if (criticalFailure) return;

		super.update(elapsed);

		if (health > Constants.HEALTH_MAX) health = Constants.HEALTH_MAX;
		if (health < Constants.HEALTH_MIN) health = Constants.HEALTH_MIN;

		if (cameraZoomRate > 0.0)
		{
			cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95); // Lerp bop multiplier back to 1.0x
			var zoomPlusBop = currentCameraZoom * cameraBopMultiplier; // Apply camera bop multiplier.
			FlxG.camera.zoom = zoomPlusBop; // Actually apply the zoom to the camera.
	  
			camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
		}

		if (needsReset)
		{
			dispatchEvent(new ScriptEvent(SONG_RETRY));

			resetCamera();

			paused = false;
			
			persistentDraw = true;
			persistentUpdate = true;
			startingSong = true;

			isPlayerDying = false;
			allSicks = true;
			songScore = 0;
			combo = 0;
			misses = 0;

			Timings.callAccuracy();
			Timings.updateAccuracy(0);

			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.volume = 1;
				FlxG.sound.music.time = 0;
				FlxG.sound.music.pitch = playbackRate;
				FlxG.sound.music.pause();
			}
			var suffix:String = (SONG.variation != null && SONG.variation != '' && SONG.variation != 'default') ? '-${SONG.variation}' : '';
		    var voiceList:Array<String> = CoolUtil.buildVoiceList(SONG, suffix);

			if (!overrideMusic)
			{
				if (vocals != null) vocals.stop();
				if (vocalsDad != null) vocalsDad.stop();

				if (SONG.needsVoices && voiceList[0] != null && voiceList[1] != null)
				{
					vocals = FlxG.sound.load(voiceList[0]);
					vocalsDad = FlxG.sound.load(voiceList[1]);
				}
			}

			if (vocals != null)
			{
				vocals.time = 0;
				vocals.volume = 1;
				vocals.pause();
			}
			if (vocalsDad != null)
			{
				vocalsDad.time = 0;
				vocalsDad.volume = 1;
				vocalsDad.pause();
			}
			if (!isPlayerDying)
			{
				plrStrums.vwooshNotes();
				cpuStrums.vwooshNotes();
			}
			plrStrums.clean();
			cpuStrums.clean();

			regenNoteData();
			cameraBopIntensity = Constants.DEFAULT_BOP_INTENSITY;
			hudCameraZoomIntensity = (cameraBopIntensity - 1.0) * 2.0;
			cameraZoomRate = Constants.DEFAULT_ZOOM_RATE;
			health = Constants.HEALTH_STARTING;

			ScriptEventDispatcher.callEvent(SongHandler.getSong(PlayState.SONG.song.toLowerCase()), new ScriptEvent(CREATE, false));
			Countdown.performCountdown();
			if(eventList.length > 1) 
				eventList.sort(sortByShit);
			needsReset = false;
		}

		if (Init.trueSettings.get('Controller Mode'))
			controllerInput();

			

		if (inCutscene)
		{
			if (dialogueBox != null && dialogueBox.alive)
			{
				if (FlxG.keys.justPressed.SHIFT) dialogueBox.closeDialog();

				// the change I made was just so that it would only take accept inputs
				if (controls.ACCEPT && dialogueBox.textStarted)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					dialogueBox.curPage += 1;
		
					if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
						dialogueBox.closeDialog()
					else
						dialogueBox.updateDialog();
				}
			}

			if (VideoCutscene.isPlaying())
			{
				if (FlxG.keys.justPressed.ENTER && canPause && VideoCutscene.cutsceneType != CutsceneType.MIDSONG)
				{
					paused = true;
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
		
		if (!inCutscene)
		{
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0) startSong();	
				}
			}
			else
			{
				Conductor.songPosition += elapsed * 1000;
		
				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;
		
					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) * 0.5;
						Conductor.lastSongPos = Conductor.songPosition;
					}
				}
			}
			
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause && !disableKeys)
				pauseGame();

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				// charting state (more on that later)
				if ((FlxG.keys.justPressed.SEVEN) && (!startingSong) && !disableKeys)
				{
					resetMusic();
					Main.switchState(new meta.state.editors.ChartingState());
				}

				if ((FlxG.keys.justPressed.EIGHT) && (!startingSong) && !disableKeys)
				{
					resetMusic();
					Main.switchState(new meta.state.editors.CharacterEditorState(SONG.characters[1], true));
				}

				if (FlxG.keys.justPressed.FIVE)
				{
					persistentUpdate = false;
					persistentDraw = true;
					openSubState(new StageOffsetSubState());
				}

				if ((FlxG.keys.justPressed.SIX))
				{
					plrStrums.botplay = !plrStrums.botplay;
					uiHUD.autoplayMark.visible = plrStrums.botplay;
					isBotPlayMode = !isBotPlayMode;
					PlayState.SONG.validScore = false;
				}
			}

			if (generatedMusic && SONG.notes[curBar] != null && !disableCamera && dad != null && boyfriend != null)
			{
				var char:BaseCharacter = dad;
				if(SONG.notes[curBar].mustHitSection)
					char = boyfriend;
				cameraFollowPoint.setPosition(char.cameraFocusPoint.x, char.cameraFocusPoint.y);
			}
			
			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !isStoryMode) health = Constants.HEALTH_MIN;

			if (health <= Constants.HEALTH_MIN && !isPracticeMode && !isPlayerDying)
			{
				paused = true;
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

	function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if ((key >= 0)
			&& !plrStrums.botplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED))
			&& (FlxG.keys.enabled && !paused))
		{
			if (generatedMusic)
			{
				var notesInRange:Array<NoteSprite> = plrStrums.getNotesMayHit();
				var holdNotesInRange:Array<SustainTrail> = plrStrums.getHoldNotesHitOrMissed();
				var notesByDirection:Array<Array<NoteSprite>> = [[], [], [], []];
				for (note in notesInRange)
					notesByDirection[note.direction].push(note);

				var notesInDirection:Array<NoteSprite> = notesByDirection[Strumline.DIRECTIONS[key]];

				if (!plrStrums.mayGhostTap() && notesInDirection.length == 0)
				{
					missNoteCheck(key);
					plrStrums.playPress(Strumline.DIRECTIONS[key]);
				}
				else if (notesInDirection.length == 0)
				{
					plrStrums.playPress(Strumline.DIRECTIONS[key]);
				}
				else
				{
					var targetNote:Null<NoteSprite> = notesInDirection.find((note) -> !note.lowPriority);
					if (targetNote == null) targetNote = notesInDirection[0];
					if (targetNote == null) return;

					goodNoteHit(targetNote, plrStrums);

					notesInDirection.remove(targetNote);

					plrStrums.playConfirm(Strumline.DIRECTIONS[key]);
				}
			}
		}
	}

	function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused)
		{
			if (key >= 0)
				plrStrums.playStatic(Strumline.DIRECTIONS[key]);
		}
	}

	// maybe theres a better place to put this, idk -saw
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

	public function checkEventNote() {
		while(eventList.length > 0) {
			var leStrumTime:Float = eventList[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				return;
			}
			if(EventsHandler.existsEvents(eventList[0].name)) 
				EventsHandler.getEvents(eventList[0].name).initFunction(eventList[0].values);
			eventList.shift();
		}
	}

	function noteCalls(elapsed:Float)
	{

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			processNotes(elapsed);
			checkEventNote();
		}
	}

	function processNotes(elapsed:Float):Void
	{
		cpuStrums.notes.forEachAlive(function(note:NoteSprite)
		{
			var hitWindowStart = note.strumTime + Conductor.safeZoneOffset - Constants.HIT_WINDOW_MS;
			var hitWindowCenter = note.strumTime + Conductor.safeZoneOffset;
			var hitWindowEnd = note.strumTime + Conductor.safeZoneOffset + Constants.HIT_WINDOW_MS;

			if (Conductor.songPosition > hitWindowEnd)
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
			else if (Conductor.songPosition > hitWindowCenter)
			{
				if (note.hasBeenHit) return;

				goodNoteHit(note, cpuStrums, false);
			}
			else if (Conductor.songPosition > hitWindowStart)
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

		cpuStrums.holdNotes.forEachAlive(function(holdNote:SustainTrail)
		{
			if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
			{
				 // Make sure the opponent keeps singing while the note is held.
				if (dad != null && dad.getCurrentAnimation().startsWith('sing')) dad.holdTimer = 0;
			}
			if (holdNote.missedNote && !holdNote.handledMiss) holdNote.handledMiss = true;
		});

		plrStrums.notes.forEachAlive(function(note:NoteSprite)
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
	  
			if (Conductor.songPosition > hitWindowEnd)
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
			else if (plrStrums.botplay && Conductor.songPosition > hitWindowCenter)
			{
			  if (note.hasBeenHit) return;
	  
			  goodNoteHit(note, plrStrums);
			}
			else if (Conductor.songPosition > hitWindowStart)
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
			  if (!plrStrums.botplay) noteMiss(note);
			  note.handledMiss = true;
			}
		});

		plrStrums.holdNotes.forEachAlive(function(holdNote:SustainTrail)
		{
			// While the hold note is being hit, and there is length on the hold note...
			if (holdNote.hitNote && !holdNote.missedNote && holdNote.sustainLength > 0)
			{
				Timings.notesHit++;
				Timings.updateAccuracy(100, true, Std.int(holdNote.sustainLength));
				health += Constants.HEALTH_HOLD_BONUS_PER_SECOND * elapsed;
				songScore += Std.int(Constants.SCORE_HOLD_BONUS_PER_SECOND * elapsed);
	  
			  // Make sure the player keeps singing while the note is held by the bot.
			  if (plrStrums.botplay && boyfriend != null && boyfriend.getCurrentAnimation().startsWith('sing')) boyfriend.holdTimer = 0;
			}
	  
			if (holdNote.missedNote && !holdNote.handledMiss) holdNote.handledMiss = true;
		});
	}

	function handleSkippedNotes():Void
	{
		for (note in plrStrums.notes.members)
		{
			if (note == null || note.hasBeenHit) continue;
			var hitWindowEnd = note.strumTime + Constants.HIT_WINDOW_MS;
	  
			if (Conductor.songPosition > hitWindowEnd) note.handledMiss = true;
		}

		plrStrums.handleSkippedNotes();
		cpuStrums.handleSkippedNotes();
	}



	function goodNoteHit(note:NoteSprite, strumline:Strumline, ?canDisplayJudgement:Bool = true):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);
		var isLate: Bool = note.strumTime < Conductor.songPosition;
	
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

		var isComboBreak:Bool = false;
		switch(foundRating)
		{
			case 'good', 'sick':
				isComboBreak = false;
			default:
				isComboBreak = true;
		}

		strumline.hitNote(note, isComboBreak);
		strumline.playNoteSplash(note.noteData.getDirection());
		if (note.holdNoteSprite != null) strumline.playNoteHoldCover(note.holdNoteSprite);
		vocals.volume = 1;
		//idk how to do this lol
		var event:NoteScriptEvent = new HitNoteScriptEvent(note, 0.0, 0, 'perfect', false, 0);
		dispatchEvent(event);

		if (event.eventCanceled) return;

		if (canDisplayJudgement)
		{
			if(!note.isHoldNote)
			{
				increaseCombo(foundRating, note.noteData.data);
				popUpScore(foundRating, isLate);
				healthCall(Timings.judgementsMap.get(foundRating)[3]);
			}
		}
	}

	function noteMiss(daNote:NoteSprite, ?popMiss:Bool = true):Void 
	{
		decreaseCombo(popMiss);

		vocals.volume = 0;
		Timings.updateAccuracy(0);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function missNoteCheck(direction:Int = 0, popMiss:Bool = false, lockMiss:Bool = false)
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
		paused = true;

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
		ScriptEventDispatcher.callEvent(SongHandler.getSong(PlayState.SONG.song.toLowerCase()), event);
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
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, isLate: Bool)
	{
		// set up the rating
		var score:Int = 50;

		if (allSicks) allSicks = false;

		displayRating(baseRating, isLate);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		songScore += score;

		popUpCombo();
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		// painful if statement
		if (((combo > 5) || (combo < 0)) && (gf != null && gf.animOffsets.exists('sad')))
			gf.playAnim('sad');

		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

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

	function increaseCombo(?baseRating:String, ?direction = 0)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(direction, false, true);
		}
	}

	public function displayRating(daRating:String, isLate: Bool, ?cache:Bool = false)
	{
		if (Init.trueSettings.get('Simply Judgements') && comboGroup.members.length > 0)
		{
			for (sprite in comboGroup.members) {
				if (sprite != null) sprite.destroy();
				comboGroup.remove(sprite);
			}
		}

		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		*/
		
		final timing =  isLate ? "late" : "early";
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? allSicks : false), timing, assetModifier);
		if (cache) rating.alpha = 0.000001;
		comboGroup.add(rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else
		{
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {
				type: FlxTweenType.BACKWARD,
				ease: FlxEase.circOut
			});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.00125
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
		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");

		for (scoreInt in 0...stringArray.length)
		{
			// numScore.loadGraphic(Paths.image('UI/' + pixelModifier + 'num' + stringArray[scoreInt]));
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? allSicks : false), assetModifier, negative, createdColor, scoreInt);
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
					startDelay: Conductor.crochet * 0.002
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

		if (FlxG.sound.music == null)
		{
			FlxG.log.error('PlayState failed to initialize instrumental!');
			return;
		}

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = endSong;
		FlxG.sound.music.volume = 1.0;
        if (FlxG.sound.music.fadeTween != null) FlxG.sound.music.fadeTween.cancel();

		vocalsDad.play();

		vocals.play();
		vocalsDad.volume = vocals.volume = 1.0;
		vocalsDad.pitch = vocals.pitch = playbackRate;

		resyncVocals();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		updateRPC(false);
		#end

		dispatchEvent(new ScriptEvent(SONG_START));
	}

	private function generateSong():Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.bpm = songData.bpm;

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = CoolUtil.dashToSpace(SONG.song) + ' - ' + curDifficulty.toUpperCase();

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);
		var suffix:String = (SONG.variation != null && SONG.variation != '' && SONG.variation != 'default') ? '-${SONG.variation}' : '';
		var voiceList:Array<String> = CoolUtil.buildVoiceList(SONG, suffix);
		curSong = songData.song;
		if(SongHandler.existsSong(SONG.song.toLowerCase())) SongHandler.getSong(PlayState.SONG.song.toLowerCase()).data = songData;
		FlxG.sound.music = FlxG.sound.load(Paths.inst(SONG.song, suffix), false, true);
		FlxG.sound.list.remove(FlxG.sound.music);
		vocals = vocalsDad = new FlxSound();
		if (SONG.needsVoices && voiceList[0] != null && voiceList[1] != null)
		{
			vocals = FlxG.sound.load(voiceList[0]);
			vocalsDad = FlxG.sound.load(voiceList[1]);
		}

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsDad);
		regenNoteData();
		

		// sometime my brain farts dont ask me why these functions were separated before

		// give the game the heads up to be able to start
		ScriptEventDispatcher.callEvent(SongHandler.getSong(PlayState.SONG.song.toLowerCase()), new ScriptEvent(CREATE, false));

		generatedMusic = true;
	}

	var prevScrollTargets:Array<Dynamic> = []; // used to snap scroll speed when things go unruely
	public function tweenScrollSpeed(?speed:Float, ?duration:Float, ?ease:Null<Float->Float>, strumlines:Array<String>):Void
	{
		cancelScrollSpeedTweens();

		// Snap to previous event value to prevent the tween breaking when another event cancels the previous tween.
		for (i in prevScrollTargets)
		{
		  var value:Float = i[0];
		  var strum:Strumline = Reflect.getProperty(this, i[1]);
		  strum.scrollSpeed = value;
		}
	
		// for next event, clean array.
		prevScrollTargets = [];
	
		for (i in strumlines)
		{
		  var value:Float = speed;
		  var strum:Strumline = Reflect.getProperty(this, i);
	
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
		  prevScrollTargets.push([value, i]);
		}
	}

	public function cancelScrollSpeedTweens()
	{
		for (tween in scrollSpeedTweens)
		{
			if (tween != null) tween.cancel();
		}
		scrollSpeedTweens = [];
	}

	function sortByShit(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	
	function resyncVocals():Void
	{
		//trace('resyncing vocal time ${vocals.time}');
		FlxG.sound.music.pause();
		vocals.pause();
		vocalsDad.pause();
		Conductor.songPosition = FlxG.sound.music.time;
		vocalsDad.time = vocals.time = Conductor.songPosition;
		FlxG.sound.music.play();
		vocals.play();
		vocalsDad.play();
		//trace('new vocal time ${Conductor.songPosition}');
	}

	override function stepHit()
	{
		super.stepHit();

		if (criticalFailure || !initialized) return;

		///*
		if (FlxG.sound.music.time >= Conductor.songPosition + 20 || FlxG.sound.music.time <= Conductor.songPosition - 20)
			resyncVocals();
		//*/
	}

	override function beatHit()
	{
		super.beatHit();

		if (criticalFailure || !initialized) return;


		if ((!Init.trueSettings.get('Reduced Movements'))  && FlxG.camera.zoom < (1.35 * FlxCamera.defaultZoom)
			&& cameraZoomRate > 0
			&& curBeat % cameraZoomRate == 0)
		{
			cameraBopMultiplier = cameraBopIntensity;
			camHUD.zoom += hudCameraZoomIntensity * defaultHUDCameraZoom;
		}

		if (SONG.notes[curBar] != null)
			if (SONG.notes[curBar].changeBPM)
				Conductor.bpm - SONG.notes[curBar].bpm;

		uiHUD.beatHit();
	}

	public static function isNull():Bool
	{
		if (instance == null || instance.stage == null || instance.isMinimalMode) return true;
		return false;
	}

	// substate stuffs

	public static function resetMusic()
	{
		// simply stated, resets the playstate's music for other states and substates
		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		if (vocals != null)
			vocals.stop();

		if(vocalsDad != null)
			vocalsDad.stop();
	}

	public static function pauseMusic()
	{
		if (FlxG.sound.music != null) FlxG.sound.music.pause();

		if (vocals != null)
			vocals.pause();

		if(vocalsDad != null)
			vocalsDad.pause();
	}

	public override function openSubState(subState:FlxSubState):Void
	{
		var shouldPause = (Std.isOfType(subState, PauseSubState) || Std.isOfType(subState, GameOverSubState));

		if (shouldPause)
		{
			// trace('null song');
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
				vocalsDad.pause();
			}
			FlxG.camera.followLerp = 0;
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

			paused = false;

			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE;

			updateRPC(false);
		}

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	public function endSong():Void
	{
		var event = new ScriptEvent(SONG_END, true);
		dispatchEvent(event);
		if (event.eventCanceled) return;

		canPause = false;
		if (FlxG.sound.music != null) FlxG.sound.music.volume = 0;
		vocals.volume = vocalsDad.volume = 0;
		
		if (SONG.validScore)
			Highscore.saveSongScore(SONG.song, curDifficulty, songScore);

		deathCounter = 0;
		
		if (isStoryMode)
		{
			// set the campaign's score higher
			campaignScore += songScore;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent))
			{
				// play menu music
				ForeverTools.resetMenuMusic();

				// change to the menu state
				openSubState(new StickerSubState(null, (sticker) -> new StoryMenuState(sticker)));

				// save the week's score if the score is valid
				if (SONG.validScore)
					Highscore.saveWeekScore(SONG.song, curDifficulty, campaignScore);

				// flush the save
				FlxG.save.flush();
			}
			else
				callDefaultSongEnd();
		}
		else
			openSubState(new StickerSubState(null, (sticker) -> new FreeplayState(sticker)));
	}

	private function callDefaultSongEnd()
	{
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		PlayState.SONG = Song.loadFromJson(PlayState.curDifficulty, PlayState.storyPlaylist[0]);
		FlxG.sound.music.pause();
		ForeverTools.killMusic([vocals, vocalsDad]);

		// deliberately did not use the main.switchstate as to not unload the assets
		FlxG.switchState(new PlayState());
	}

	var dialogueBox:DialogueBox;

	function callTextbox()
	{
		var dialogPath = Paths.json(SONG.song.toLowerCase() + '/dialogue');
		if (sys.FileSystem.exists(dialogPath))
		{
			startedCountdown = false;

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(dialogPath));
			dialogueBox.camera = camAlt;
			dialogueBox.whenDaFinish = startCountdown;

			add(dialogueBox);
		}
		else
			startCountdown();
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
						return !isStoryMode;
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

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
