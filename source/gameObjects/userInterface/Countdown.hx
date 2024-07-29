package gameObjects.userInterface;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import meta.modding.events.ScriptEventDispatcher;
import meta.modding.module.ModuleHandler;
import meta.modding.events.ScriptEvent;
import meta.modding.events.ScriptEvent.CountdownScriptEvent;
import flixel.util.FlxTimer;


class Countdown
{
  /**
   * The current step of the countdown.
   */
  public static var countdownStep(default, null):CountdownStep = BEFORE;

  /**
   * The currently running countdown. This will be null if there is no countdown running.
   */
  static var countdownTimer:FlxTimer = null;

  /**
   * Performs the countdown.
   * Pauses the song, plays the countdown graphics/sound, and then starts the song.
   * This will automatically stop and restart the countdown if it is already running.
   * @returns `false` if the countdown was cancelled by a script.
   */
  public static function performCountdown(assetModifier, changeableSkin):Bool
  {
    countdownStep = BEFORE;
    var cancelled:Bool = propagateCountdownEvent(countdownStep);
    if (cancelled)
    {
      return false;
    }

    // Stop any existing countdown.
    stopCountdown();

    PlayState.instance.startedCountdown = true;
    Conductor.songPosition = -(Conductor.crochet * 5);
    // Handle onBeatHit events manually
    // @:privateAccess
    // PlayState.instance.dispatchEvent(new SongTimeScriptEvent(SONG_BEAT_HIT, 0, 0));

    // The timer function gets called based on the beat of the song.
    countdownTimer = new FlxTimer();

    countdownTimer.start(Conductor.crochet * 0.001, function(tmr:FlxTimer) {
      if (PlayState.instance == null)
      {
        tmr.cancel();
        return;
      }

      countdownStep = decrement(countdownStep);

      // onBeatHit events are now properly dispatched by the Conductor even at negative timestamps,
      // so calling this is no longer necessary.
      // PlayState.instance.dispatchEvent(new SongTimeScriptEvent(SONG_BEAT_HIT, 0, 0));

      // Countdown graphic.
      showCountdownGraphic(countdownStep, assetModifier, changeableSkin);

      // Countdown sound.
      playCountdownSound(countdownStep, assetModifier);

      // Event handling bullshit.
      var cancelled:Bool = propagateCountdownEvent(countdownStep);

      if (cancelled)
      {
        pauseCountdown();
      }

      if (countdownStep == AFTER)
      {
        stopCountdown();
      }
    }, 5); // Before, 3, 2, 1, GO!, After

    return true;
  }

  /**
   * @return TRUE if the event was cancelled.
   */
  static function propagateCountdownEvent(index:CountdownStep):Bool
  {
    var event:ScriptEvent;

    switch (index)
    {
      case BEFORE:
        event = new CountdownScriptEvent(COUNTDOWN_START, index);
      case THREE | TWO | ONE | GO: // I didn't know you could use `|` in a switch/case block!
        event = new CountdownScriptEvent(COUNTDOWN_STEP, index);
      case AFTER:
        event = new CountdownScriptEvent(COUNTDOWN_END, index, false);
      default:
        return true;
    }

    // Modules, stages, characters.
    @:privateAccess
    PlayState.instance.dispatchEvent(event);

    return event.eventCanceled;
  }

  /**
   * Pauses the countdown at the current step. You can start it up again later by calling resumeCountdown().
   *
   * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStep event.
   */
  public static function pauseCountdown()
  {
    if (countdownTimer != null && !countdownTimer.finished)
    {
      countdownTimer.active = false;
    }
  }

  /**
   * Resumes the countdown at the current step. Only makes sense if you called pauseCountdown() first.
   *
   * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStep event.
   */
  public static function resumeCountdown()
  {
    if (countdownTimer != null && !countdownTimer.finished)
    {
      countdownTimer.active = true;
    }
  }

  /**
   * Stops the countdown at the current step. You will have to restart it again later.
   *
   * If you want to call this from a module, it's better to use the event system and cancel the onCountdownStart event.
   */
  public static function stopCountdown()
  {
    if (countdownTimer != null)
    {
      countdownTimer.cancel();
      countdownTimer.destroy();
      countdownTimer = null;
    }
  }

  /**
   * Stops the current countdown, then starts the song for you.
   */
  public static function skipCountdown()
  {
    stopCountdown();
    // This will trigger PlayState.startSong()
    Conductor.songPosition = 0;
    // PlayState.isInCountdown = false;
  }

  /**
   * Resets the countdown. Only works if it's already running.
   */
  public static function resetCountdown()
  {
    if (countdownTimer != null)
    {
      countdownTimer.reset();
    }
  }

  /**
   * Retrieves the graphic to use for this step of the countdown.
   * TODO: Make this less dumb. Unhardcode it? Use modules? Use notestyles?
   *
   * This is public so modules can do lol funny shit.
   */
  public static function showCountdownGraphic(index:CountdownStep, assetModifier, changeableSkin):Void
  {
    var spritePath:String = null;
    switch (index)
    {
      case TWO:
        spritePath = 'ready';
      case ONE:
        spritePath = 'set';
      case GO:
        spritePath = 'go';
      default:
        // null
    }

    

    if (spritePath == null) return;

    var countdownSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset(spritePath, assetModifier, changeableSkin, 'UI')));
    countdownSprite.scrollFactor.set();

    if (assetModifier == 'pixel')
    {
        countdownSprite.setGraphicSize(Std.int(countdownSprite.width * Constants.PIXEL_ART_SCALE));
        countdownSprite.antialiasing = false;
    }
    countdownSprite.updateHitbox();
    countdownSprite.screenCenter();

    // Fade sprite in, then out, then destroy it.
    FlxTween.tween(countdownSprite, {y: countdownSprite.y += 100, alpha: 0}, Conductor.crochet * 0.001,
    {
        ease: FlxEase.cubeInOut,
        onComplete: function(twn:FlxTween) {
          countdownSprite.destroy();
        }
    });

    PlayState.instance.add(countdownSprite);
  }

  /**
   * Retrieves the sound file to use for this step of the countdown.
   * TODO: Make this less dumb. Unhardcode it? Use modules? Use notestyles?
   *
   * This is public so modules can do lol funny shit.
   */
  public static function playCountdownSound(index:CountdownStep, assetModifier):Void
  {
    var soundPath:String = null;

    switch (index)
    {
      case THREE:
        soundPath = 'intro3';
      case TWO:
        soundPath = 'intro2';
      case ONE:
        soundPath = 'intro1';
      case GO:
        soundPath = 'introGo';
      default:
        // null
    }

    if (soundPath == null) return;

    FlxG.sound.play(Paths.sound(soundPath + '-' + assetModifier), Constants.COUNTDOWN_VOLUME);
  }

  public static function decrement(step:CountdownStep):CountdownStep
  {
    switch (step)
    {
      case BEFORE:
        return THREE;
      case THREE:
        return TWO;
      case TWO:
        return ONE;
      case ONE:
        return GO;
      case GO:
        return AFTER;

      default:
        return AFTER;
    }
  }
}

/**
 * The countdown step.
 * This can't be an enum abstract because scripts may need it.
 */
enum CountdownStep
{
  BEFORE;
  THREE;
  TWO;
  ONE;
  GO;
  AFTER;
}