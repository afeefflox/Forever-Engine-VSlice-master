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
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.*;
import meta.MusicBeat.MusicBeatState;
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

	public static var storyDifficulty:Int = 2;

	public static var songMusic:FlxSound;
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

	public var unspawnNotes:Array<Note> = [];
	public var eventList:Array<SwagEvent> = [];
	private var ratingArray:Array<String> = [];
	private var allSicks:Bool = true;

	// if you ever wanna add more keys
	private var numberOfKeys:Int = 4;

	public var cameraFollowPoint:FlxObject;
	public var cameraFollowTween:FlxTween;
	public var cameraZoomTween:FlxTween;
	
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

	var paused:Bool = false;
	public var startingSong:Bool = false;
	public var startedCountdown:Bool = false;
	public var inCutscene:Bool = false;
	public var isPracticeMode:Bool = false;
	public var isBotPlayMode:Bool = false;
	public var isPlayerDying:Bool = false;
	public var isMinimalMode:Bool = false;
	public var isChartingMode:Bool = false;
	public var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camAlt:FlxCamera;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result

	public var forceZoom:Array<Float> = [0, 0, 0, 0];
	

	var storyDifficultyText:String = "";
	
	public static var iconRPC:String = "";
	public static var songLength:Float = 0;
	public var uiHUD:ClassHUD;

	public static var daPixelZoom:Float = 6;
	public static var determinedChartType:String = "";

	// strumlines
	public var cpuStrums:Strumline;
	public var plrStrums:Strumline;
	public var strumLines:FlxTypedGroup<Strumline>;

	public var comboGroup:FlxSpriteGroup;
	var stickerSubState:StickerSubState;
	
	public function new(?stickers:StickerSubState)
	{
		super();
		if (stickers != null)
			stickerSubState = stickers;
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

		Conductor.songPosition = -(Conductor.crochet * 4);

		generateSong();

		startingSong = startedCountdown = true;

		resetCamera();
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		
		if (stickerSubState != null)
		{
			this.persistentUpdate = this.persistentDraw = true;
			openSubState(stickerSubState);
			stickerSubState.degenStickers();
		}

		Paths.clearUnusedMemory();
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
		strumLines = new FlxTypedGroup<Strumline>();
		var placement = (FlxG.width * 0.5);
		cpuStrums = new Strumline(placement - (FlxG.width * 0.25), false, true, false, 4, Init.trueSettings.get('Downscroll'));
		cpuStrums.visible = !Init.trueSettings.get('Centered Notefield');
		plrStrums = new Strumline(placement + (!Init.trueSettings.get('Centered Notefield') ? (FlxG.width * 0.25) : 0), true, false, true,
			4, Init.trueSettings.get('Downscroll'));

		strumLines.add(cpuStrums);
		strumLines.add(plrStrums);

		strumLines.camera = camHUD;
		add(strumLines);
	}

	function initCameras() {
		camGame = FlxG.camera;
		camHUD = camAlt = new FlxCamera();
		camHUD.bgColor = camAlt.bgColor = 0x00000000;
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
		  var event:ScriptEvent = new ScriptEvent(CREATE, false);
		  ScriptEventDispatcher.callEvent(stage, event);
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
	  

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if ((key >= 0)
			&& !plrStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Init.trueSettings.get('Controller Mode'))
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = songMusic.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				plrStrums.notesGroup.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
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
							goodNoteHit(coolNote, plrStrums, firstNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
						missNoteCheck(true, key, true);
				Conductor.songPosition = previousTime;
			}

			if (plrStrums.receptors.members[key] != null
				&& plrStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				plrStrums.receptors.members[key].playAnim('pressed');
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			// receptor reset
			if (key >= 0 && plrStrums.receptors.members[key] != null)
				plrStrums.receptors.members[key].playAnim('static');
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
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

	override public function destroy()
	{
		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		performCleanup();


		super.destroy();
	}

	function performCleanup():Void
	{
		// If the camera is being tweened, stop it.
		cancelAllCameraTweens();

		// Dispatch the destroy event.
		dispatchEvent(new ScriptEvent(DESTROY, false));

		if (overrideMusic)
		{
			for(i in [songMusic, vocals, vocalsDad])
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
			for(i in [songMusic, vocals, vocalsDad])
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
		
		// Clear the static reference to this state.
		instance = null;
	}

	override function debug_refreshModules():Void
	{
		criticalFailure = true;

		if (!overrideMusic)
		{
			// Stop the instrumental.
			if (songMusic != null)
			{
				songMusic.destroy();
				songMusic = null;
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
			if (songMusic != null) songMusic.stop();
			for(i in [vocals, vocalsDad])
			{
				if (i != null && i.exists) i.stop();
			}
			if (vocals != null && vocals.exists) vocals.stop();
		}
		
		super.debug_refreshModules();		

		var event:ScriptEvent = new ScriptEvent(CREATE, false);
		if(SongHandler.existsSong(curSong)) ScriptEventDispatcher.callEvent(SongHandler.getSong(curSong), event);
	}

	var lastBar:Int = 0;

	override public function update(elapsed:Float)
	{
		if (criticalFailure) return;

		super.update(elapsed);

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive)
		{
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

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

		if (!inCutscene)
		{
			// pause the game if the game is allowed to pause and enter is pressed
			if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
				pauseGame();

			// make sure you're not cheating lol
			if (!isStoryMode)
			{
				// charting state (more on that later)
				if ((FlxG.keys.justPressed.SEVEN) && (!startingSong))
				{
					resetMusic();
					Main.switchState(new meta.state.editors.ChartingState());
				}

				if ((FlxG.keys.justPressed.EIGHT) && (!startingSong))
				{
					resetMusic();
					Main.switchState(new meta.state.editors.CharacterEditorState(SONG.characters[1], true));
				}

				if ((FlxG.keys.justPressed.SIX))
				{
					plrStrums.autoplay = !plrStrums.autoplay;
					uiHUD.autoplayMark.visible = plrStrums.autoplay;
					isBotPlayMode = !isBotPlayMode;
					PlayState.SONG.validScore = false;
				}
			}

			///*
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
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

			if (generatedMusic && SONG.notes[curBar] != null && !disableCamera && dad != null && boyfriend != null)
			{
				if (curBar != lastBar)
				{
					// section reset stuff
					var lastMustHit:Bool = SONG.notes[lastBar].mustHitSection;
					if (SONG.notes[curBar].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastBar = Std.int(curBeat * 0.25);
				}

				var char:BaseCharacter = dad;
				if(SONG.notes[curBar].mustHitSection)
					char = boyfriend;
				cameraFollowPoint.setPosition(char.cameraFocusPoint.x + camDisplaceX, char.cameraFocusPoint.y + camDisplaceY);
			}

			if (health > Constants.HEALTH_MAX) health = Constants.HEALTH_MAX;
			if (health < Constants.HEALTH_MIN) health = Constants.HEALTH_MIN;

			if (cameraZoomRate > 0.0)
			{
				cameraBopMultiplier = FlxMath.lerp(1.0, cameraBopMultiplier, 0.95); // Lerp bop multiplier back to 1.0x
				var zoomPlusBop = currentCameraZoom * cameraBopMultiplier; // Apply camera bop multiplier.
				FlxG.camera.zoom = zoomPlusBop; // Actually apply the zoom to the camera.
		  
				camHUD.zoom = FlxMath.lerp(defaultHUDCameraZoom, camHUD.zoom, 0.95);
			}

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong && !isStoryMode)
			{
				health = Constants.HEALTH_MIN;
			}

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

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var dunceNote:Note = unspawnNotes[0];
				// push note to its correct strumline
				strumLines.members[Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / numberOfKeys)].push(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
				var event:NoteScriptEvent = new NoteScriptEvent(NOTE_INCOMING, dunceNote, 0, false);
				dispatchEvent(event);
			}

			noteCalls();
			if (Init.trueSettings.get('Controller Mode'))
				controllerInput();
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

	function noteCalls()
	{
		// reset strums
		for (strumline in strumLines)
		{
			// handle strumline stuffs
			for (uiNote in strumline.receptors)
			{
				if (strumline.autoplay)
					strumCallsAuto(uiNote);
			}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (Init.trueSettings.get('Downscroll'))
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
					var receptorPosY:Float = strumline.receptors.members[Math.floor(daNote.noteData)].y + Note.swagWidth / 6;
					var psuedoY:Float = (downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * roundedSpeed)));
					var psuedoX = 25 + daNote.noteVisualOffset;

					daNote.y = receptorPosY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX);
					// painful math equation
					daNote.x = strumline.receptors.members[Math.floor(daNote.noteData)].x
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY);

					// also set note rotation
					daNote.angle = -daNote.noteDirection;

					// shitty note hack I hate it so much
					var center:Float = receptorPosY + Note.swagWidth * 0.5;
					if (daNote.isSustainNote)
					{
						daNote.y -= ((daNote.height * 0.5) * downscrollMultiplier);
						if ((daNote.animation.curAnim.name.endsWith('holdend')) && (daNote.prevNote != null))
						{
							daNote.y -= ((daNote.prevNote.height * 0.5) * downscrollMultiplier);
							if (Init.trueSettings.get('Downscroll'))
							{
								daNote.y += (daNote.height * 2);
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
								{
									// set the end hold offset yeah I hate that I fix this like this
									daNote.endHoldOffset = (daNote.prevNote.y - (daNote.y + daNote.height));
									//trace(daNote.endHoldOffset);
								}
								else
									daNote.y += daNote.endHoldOffset;
							}
							else // this system is funny like that
								daNote.y += ((daNote.height * 0.5) * downscrollMultiplier);
						}

						if (Init.trueSettings.get('Downscroll'))
						{
							daNote.flipY = true;
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
						daNote.active = daNote.visible = false;
					else
						daNote.visible = daNote.active = true;

					if (!daNote.ignoreNote && !daNote.tooLate && daNote.strumTime < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit)
					{
						if ((!daNote.tooLate) && (daNote.mustPress))
						{
							if (!daNote.isSustainNote)
							{
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;

								noteMiss(daNote, strumline, true);
							}
							else if (daNote.isSustainNote)
							{
								if (daNote.parentNote != null)
								{
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
										{
											//trace('hold amount ${parentNote.childrenNotes.length}, note is late?' + note.tooLate + ', ' + breakFromLate);
											if (note.tooLate && !note.wasGoodHit)
												breakFromLate = true;
										}
										if (!breakFromLate)
										{
											noteMiss(daNote, strumline, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!Init.trueSettings.get('Downscroll')) && (daNote.y < -daNote.height))
						|| ((Init.trueSettings.get('Downscroll')) && (daNote.y > (FlxG.height + daNote.height))))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});

				// unoptimised asf camera control based on strums
				strumCameraRoll(strumline.receptors, (strumline == plrStrums));
			}
			checkEventNote();
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = daNote.exists = false;
		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(coolNote:Note, characterStrums:Strumline, ?canDisplayJudgement:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			if(!coolNote.mustPress) //Opponent of course :/
				coolNote.hitByOpponent = true;

			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			if(NoteTypeRegistry.instance.hasEntry(coolNote.noteType) && coolNote.noteType != null && coolNote.noteType.length > 1)
				NoteTypeRegistry.instance.fetchEntry(coolNote.noteType).hitFunction(coolNote);

			if (characterStrums.receptors.members[coolNote.noteData] != null)
				characterStrums.receptors.members[coolNote.noteData].playAnim('confirm', true);

			var event:NoteScriptEvent = new HitNoteScriptEvent(coolNote, 0.0, 0, 'perfect', false, 0);
			dispatchEvent(event);

			if (event.eventCanceled) return;


			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				var isLate: Bool = coolNote.strumTime < Conductor.songPosition;

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

				if (!coolNote.isSustainNote)
				{
					increaseCombo(foundRating, coolNote.noteData);
					popUpScore(foundRating, isLate, characterStrums, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);
				}
				else if (coolNote.isSustainNote)
				{
					
					// call updated accuracy stuffs
					if (coolNote.parentNote != null)
					{
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						health += Constants.HEALTH_HOLD_BONUS_PER_SECOND * FlxG.elapsed;
						songScore += Std.int(Constants.SCORE_HOLD_BONUS_PER_SECOND * FlxG.elapsed);
					}
				}
			}

			if (!coolNote.isSustainNote)
				destroyNote(characterStrums, coolNote);
			//
		}
	}

	function noteMiss(daNote:Note, characterStrums:Strumline, ?popMiss:Bool = true):Void 
	{
		decreaseCombo(popMiss);

		var event:NoteScriptEvent = new NoteScriptEvent(NOTE_MISS, daNote, 0, 0, false);
		dispatchEvent(event);

		if (event.eventCanceled) return;

		if(NoteTypeRegistry.instance.hasEntry(daNote.noteType) && daNote.noteType != null && daNote.noteType.length > 1)
			NoteTypeRegistry.instance.fetchEntry(daNote.noteType).hitFunction(daNote);

		vocals.volume = 0;
		Timings.updateAccuracy(0);
		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
	}

	function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, popMiss:Bool = false, lockMiss:Bool = false)
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

	private function strumCallsAuto(cStrum:UIStaticArrow, ?callType:Int = 1, ?daNote:Note):Void
	{
		switch (callType)
		{
			case 1:
				// end the animation if the calltype is 1 and it is done
				if ((cStrum.animation.finished) && (cStrum.canFinishAnimation))
					cStrum.playAnim('static');
			default:
				// check if it is the correct strum
				if (daNote.noteData == cStrum.ID)
				{
					// if (cStrum.animation.curAnim.name != 'confirm')
					cStrum.playAnim('confirm'); // play the correct strum's confirmation animation (haha rhymes)

					// stuff for sustain notes
					if ((daNote.isSustainNote) && (!daNote.animation.curAnim.name.endsWith('holdend')))
						cStrum.canFinishAnimation = false; // basically, make it so the animation can't be finished if there's a sustain note below
					else
						cStrum.canFinishAnimation = true;
				}
		}
	}

	private function mainControls(daNote:Note, strumline:Strumline, autoplay:Bool):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// kill the note, then remove it from the array
				var canDisplayJudgement = false;
				if (strumline.displayJudgements)
				{
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
							canDisplayJudgement = false;
					}
					notesPressedAutoplay.push(daNote);
				}
				goodNoteHit(daNote, strumline, canDisplayJudgement);
			}
		}

		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if (!autoplay)
		{
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.mustPress
						&& !coolNote.tooLate
						&& coolNote.isSustainNote
						&& holdControls[coolNote.noteData])
						goodNoteHit(coolNote, strumline);
				});
			}
		}
	}

	private function strumCameraRoll(cStrum:FlxTypedGroup<UIStaticArrow>, mustHit:Bool)
	{
		if (!Init.trueSettings.get('No Camera Note Movement'))
		{
			var camDisplaceExtend:Float = 15;
			if (PlayState.SONG.notes[curBar] != null)
			{
				if ((PlayState.SONG.notes[curBar].mustHitSection && mustHit)
					|| (!PlayState.SONG.notes[curBar].mustHitSection && !mustHit))
				{
					camDisplaceX = 0;
					if (cStrum.members[0].animation.curAnim.name == 'confirm')
						camDisplaceX -= camDisplaceExtend;
					if (cStrum.members[3].animation.curAnim.name == 'confirm')
						camDisplaceX += camDisplaceExtend;

					camDisplaceY = 0;
					if (cStrum.members[1].animation.curAnim.name == 'confirm')
						camDisplaceY += camDisplaceExtend;
					if (cStrum.members[2].animation.curAnim.name == 'confirm')
						camDisplaceY -= camDisplaceExtend;
				}
			}
		}
		//
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

		// stop all tweens and timers
		FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
		{
			if (!tmr.finished)
				tmr.active = false;
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween)
		{
			if (!twn.finished)
				twn.active = false;
		});

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
		if(SongHandler.existsSong(curSong)) ScriptEventDispatcher.callEvent(SongHandler.getSong(curSong), event);
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

	function popUpScore(baseRating:String, isLate: Bool, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		// notesplashes
		if (baseRating == "sick") 
			strumline.createSplash(coolNote);
		else
			// if it isn't a sick, and you had a sick combo, then it becomes not sick :(
			if (allSicks)
				allSicks = false;

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
				missNoteCheck(true, direction, false, true);
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
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? allSicks : false), timing, assetModifier, changeableSkin, 'UI');
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
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? allSicks : false), assetModifier, changeableSkin, 'UI',
				negative, createdColor, scoreInt);
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

		if (songMusic == null)
		{
			FlxG.log.error('PlayState failed to initialize instrumental!');
			return;
		}

		songMusic.play();
		songMusic.pitch = playbackRate;
		songMusic.onComplete = endSong;
		if (songMusic.fadeTween != null) songMusic.fadeTween.cancel();

		vocalsDad.play();

		vocals.play();
		vocalsDad.volume = vocals.volume = 1.0;
		vocalsDad.pitch = vocals.pitch = playbackRate;

		resyncVocals();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = songMusic.length;

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
		if(SongHandler.existsSong(curSong)) SongHandler.getSong(curSong).data = songData;
		songMusic = new FlxSound().loadEmbedded(Paths.inst(SONG.song, suffix), false, true);
		vocals = vocalsDad = new FlxSound();
		if (SONG.needsVoices && voiceList[0] != null && voiceList[1] != null)
		{
			vocals = FlxG.sound.load(voiceList[0]);
			vocalsDad = FlxG.sound.load(voiceList[1]);
		}

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(vocalsDad);
		// generate the chart
		unspawnNotes = ChartLoader.generateChartType(SONG);
		if(eventList.length > 1) 
			eventList.sort(sortByShit);
		// sometime my brain farts dont ask me why these functions were separated before

		// sort through them
		unspawnNotes.sort(sortByShit);
		// give the game the heads up to be able to start
		var event:ScriptEvent = new ScriptEvent(CREATE, false);
		ScriptEventDispatcher.callEvent(SongHandler.getSong(curSong), event);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Dynamic, Obj2:Dynamic):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	
	function resyncVocals():Void
	{
		//trace('resyncing vocal time ${vocals.time}');
		songMusic.pause();
		vocals.pause();
		vocalsDad.pause();
		Conductor.songPosition = songMusic.time;
		vocalsDad.time = vocals.time = Conductor.songPosition;
		songMusic.play();
		vocals.play();
		vocalsDad.play();
		//trace('new vocal time ${Conductor.songPosition}');
	}

	override function stepHit()
	{
		super.stepHit();

		if (criticalFailure || !initialized) return;

		///*
		if (songMusic.time >= Conductor.songPosition + 20 || songMusic.time <= Conductor.songPosition - 20)
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
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();

		if(vocalsDad != null)
			vocalsDad.stop();
	}

	public override function openSubState(subState:FlxSubState):Void
	{
		var shouldPause = (Std.isOfType(subState, PauseSubState) || Std.isOfType(subState, GameOverSubState));

		if (shouldPause)
		{
			// trace('null song');
			if (songMusic != null)
			{
				songMusic.pause();
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

			if (songMusic != null && !startingSong)
				resyncVocals();

			// resume all tweens and timers
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
			{
				if (!tmr.finished)
					tmr.active = true;
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween)
			{
				if (!twn.finished)
					twn.active = true;
			});

			FlxG.camera.followLerp = Constants.DEFAULT_CAMERA_FOLLOW_RATE;

			updateRPC(false);
		}

		Paths.clearUnusedMemory();

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	function endSong():Void
	{
		var event = new ScriptEvent(SONG_END, true);
		dispatchEvent(event);
		if (event.eventCanceled) return;

		canPause = false;
		songMusic.volume = vocals.volume = vocalsDad.volume = 0;
		
		if (SONG.validScore)
			Highscore.saveSongScore(SONG.song, curDifficulty, songScore);

		deathCounter = 0;

		if (!isStoryMode)
		{
			Main.switchState(new FreeplayState());
		}
		else
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

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				// change to the menu state
				Main.switchState(new StoryMenuState());

				// save the week's score if the score is valid
				if (SONG.validScore)
					Highscore.saveWeekScore(SONG.song, curDifficulty, campaignScore);

				// flush the save
				FlxG.save.flush();
			}
			else
				callDefaultSongEnd();
		}
	}

	private function callDefaultSongEnd()
	{
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		PlayState.SONG = Song.loadFromJson(PlayState.curDifficulty, PlayState.storyPlaylist[0]);
		ForeverTools.killMusic([songMusic, vocals, vocalsDad]);

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

	private function startCountdown():Void
	{
		var result:Bool = Countdown.performCountdown(assetModifier, changeableSkin);
		if (!result) return;

		inCutscene = false;
		camHUD.visible = true;
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
