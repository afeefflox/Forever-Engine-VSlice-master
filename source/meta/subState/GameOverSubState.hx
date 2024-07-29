package meta.subState;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import meta.MusicBeat.MusicBeatSubState;
import meta.data.Conductor.BPMChangeEvent;
import meta.data.Conductor;
import meta.state.*;
import meta.state.menus.*;


typedef GameOverParams =
{
  var isChartingMode:Bool;
  var transparent:Bool;
}

class GameOverSubState extends MusicBeatSubState
{
	public static var instance:Null<GameOverSubState> = null;
	public static var animationSuffix:String = '';
	public static var musicSuffix:String = '';
	public static var blueBallSuffix:String = '';

	static var blueballed:Bool = false;

	var boyfriend:Null<BaseCharacter> = null;
	var cameraFollowPoint:FlxObject;
	var gameOverMusic:Null<FlxSound> = null;

	var isEnding:Bool = false;
	var isStarting:Bool = true;
	var isChartingMode:Bool = false;
	var mustNotExit:Bool = false;  
	var transparent:Bool;  
	static final CAMERA_ZOOM_DURATION:Float = 0.5;  
	var targetCameraZoom:Float = 1.0;

	public static function reset():Void
	{
		animationSuffix = musicSuffix = blueBallSuffix = '';
		blueballed = false;
	}

	public function new(params:GameOverParams)
	{
		super();
	  
		this.isChartingMode = params?.isChartingMode ?? false;
		transparent = params.transparent;
	  
		cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
	}

	public override function create():Void
	{
		instance = this;

		super.create();

		var playState = PlayState.instance;

		// Add a black background to the screen.
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		bg.alpha = transparent ? 0.25 : 1.0;
		bg.scrollFactor.set();
		bg.screenCenter();
		add(bg);

		if(!PlayState.instance.isMinimalMode)
		{
			boyfriend = PlayState.instance.boyfriend;
			boyfriend.isDead = true;
			add(boyfriend);
			boyfriend.resetCharacter();
		}

		setCameraTarget();
	}

	function setCameraTarget():Void
	{
		if (PlayState.instance.isMinimalMode || boyfriend == null) return;

		// Assign a camera follow point to the boyfriend's position.
		cameraFollowPoint = new FlxObject(PlayState.instance.cameraFollowPoint.x, PlayState.instance.cameraFollowPoint.y, 1, 1);
		cameraFollowPoint.x = boyfriend.getGraphicMidpoint().x;
		cameraFollowPoint.y = boyfriend.getGraphicMidpoint().y;
		var offsets:Array<Float> = boyfriend.getDeathCameraOffsets();
		cameraFollowPoint.x += offsets[0];
		cameraFollowPoint.y += offsets[1];
		add(cameraFollowPoint);
	
		FlxG.camera.target = null;
		FlxG.camera.follow(cameraFollowPoint, LOCKON, Constants.DEFAULT_CAMERA_FOLLOW_RATE / 2);
		targetCameraZoom = (PlayState?.instance?.stage?.camZoom ?? 1.0) * boyfriend.getDeathCameraZoom();
	}

	public function resetCameraZoom():Void
		FlxG.camera.zoom = PlayState?.instance?.stage?.camZoom ?? 1.0;

	var hasStartedAnimation:Bool = false;

    override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!hasStartedAnimation)
		{
			hasStartedAnimation = true;

			if (boyfriend == null || PlayState.instance.isMinimalMode)
				playBlueBalledSFX();
			else
			{
			  if (boyfriend.hasAnimation('fakeoutDeath') && FlxG.random.bool((1 / 4096) * 100))
				boyfriend.playAnim('fakeoutDeath', true, false);
			  else
			  {
				boyfriend.playAnim('firstDeath', true, false); 
				playBlueBalledSFX();
			  }
			}			
		}

		FlxG.camera.zoom = MathUtil.smoothLerp(FlxG.camera.zoom, targetCameraZoom, elapsed, CAMERA_ZOOM_DURATION);

		if (controls.ACCEPT && blueballed && !mustNotExit)
		{
			blueballed = false;
			confirmDeath();
		}

		if (controls.BACK && !mustNotExit && !isEnding)
		{
			isEnding = true;
			blueballed = false;
			PlayState.instance.deathCounter = 0;
			if (gameOverMusic != null) gameOverMusic.stop();
			openSubState(new StickerSubState(null, (sticker) -> PlayState.isStoryMode ? new StoryMenuState(sticker) :  new FreeplayState(sticker)));
		}

		if (gameOverMusic != null && gameOverMusic.playing)
			Conductor.songPosition = gameOverMusic.time;
		else if (boyfriend != null)
		{
			if (boyfriend.getCurrentAnimation().startsWith('firstDeath') && boyfriend.isAnimationFinished())
            {
              startDeathMusic(1.0, false);
              boyfriend.playAnim('deathLoop' + animationSuffix);
            }
		}
	}

	function confirmDeath():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			startDeathMusic(1.0, true); // isEnding changes this function's behavior.
	  
			if (!PlayState.instance.isMinimalMode || boyfriend != null)
			{
			  boyfriend.playAnim('deathConfirm' + animationSuffix, true);
			}

			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function()
				{
					Main.switchState(new PlayState());
				});
			});
		}
	}

	public override function dispatchEvent(event:ScriptEvent):Void
	{
		super.dispatchEvent(event);
	  
		ScriptEventDispatcher.callEvent(boyfriend, event);
	}

	function resolveMusicPath(suffix:String, starting:Bool = false, ending:Bool = false):Null<String>
	{
		var basePath:String = 'gameOver';
		if (ending) basePath += 'End';
	  
		var musicPath:String = Paths.musicPaths(basePath + suffix);
		while (!Paths.exists(musicPath, SOUND) && suffix.length > 0)
		{
			suffix = suffix.split('-').slice(0, -1).join('-');
			musicPath = Paths.musicPaths(basePath + suffix);
		}
		if (!Paths.exists(musicPath, SOUND)) return null;
		trace('Resolved music path: ' + musicPath);
		return musicPath;
	}

	public function startDeathMusic(startingVolume:Float = 1, force:Bool = false):Void
	{
		var musicPath:Null<String> = resolveMusicPath(musicSuffix, isStarting, isEnding);
		var onComplete:() -> Void = () -> {};

		if (isStarting)
		{
			if (musicPath == null)
			{
				// Looked for starting music and didn't find it. Use middle music instead.
				isStarting = false;
				musicPath = resolveMusicPath(musicSuffix, isStarting, isEnding);
			}
			else
			{
				onComplete = function() {
					isStarting = true;
					// We need to force to ensure that the non-starting music plays.
					startDeathMusic(1.0, true);
				};
			}
		}

		if (musicPath == null)
		{
			FlxG.log.warn('[GAMEOVER] Could not find game over music at path ($musicPath)!');
			return;
		}
		else if (gameOverMusic == null || !gameOverMusic.playing || force)
		{
			if (gameOverMusic != null) gameOverMusic.stop();

			gameOverMusic = FlxG.sound.load(musicPath);
			if (gameOverMusic == null) return;
	  
			gameOverMusic.volume = startingVolume;
			gameOverMusic.looped = !(isEnding || isStarting);
			gameOverMusic.onComplete = onComplete;
			gameOverMusic.play();			
		}
	}

	public static function playBlueBalledSFX():Void
	{
		blueballed = true;
		if (Paths.exists(Paths.soundPaths('fnf_loss_sfx'), SOUND))
			FlxG.sound.play(Paths.sound('fnf_loss_sfx' + blueBallSuffix));
		else
			FlxG.log.error('Missing blue ball sound effect: assets/sounds/fnf_loss_sfx' + blueBallSuffix);
	}

	public override function destroy():Void
	{
		super.destroy();
		if (gameOverMusic != null)
		{
			gameOverMusic.stop();
			gameOverMusic = null;
		}
		blueballed = false;
		instance = null;
	}

	public override function toString():String
	{
		return 'GameOverSubState';
	}
}
