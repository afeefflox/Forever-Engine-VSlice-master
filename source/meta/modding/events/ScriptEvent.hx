package meta.modding.events;

import flixel.FlxState;
import flixel.FlxSubState;
import gameObjects.userInterface.Countdown.CountdownStep;
import openfl.events.EventType;
import openfl.events.KeyboardEvent;

/**
 * This is a base class for all events that are issued to scripted classes.
 * It can be used to identify the type of event called, store data, and cancel event propagation.
 */
class ScriptEvent
{
  /**
   * If true, the behavior associated with this event can be prevented.
   * For example, cancelling COUNTDOWN_START should prevent the countdown from starting,
   * until another script restarts it, or cancelling NOTE_HIT should cause the note to be missed.
   */
  public var cancelable(default, null):Bool;

  /**
   * The type associated with the event.
   */
  public var type(default, null):ScriptEventType;

  /**
   * Whether the event should continue to be triggered on additional targets.
   */
  public var shouldPropagate(default, null):Bool;

  /**
   * Whether the event has been canceled by one of the scripts that received it.
   */
  public var eventCanceled(default, null):Bool;

  public function new(type:ScriptEventType, cancelable:Bool = false):Void
  {
    this.type = type;
    this.cancelable = cancelable;
    this.eventCanceled = false;
    this.shouldPropagate = true;
  }

  /**
   * Call this function on a cancelable event to cancel the associated behavior.
   * For example, cancelling COUNTDOWN_START will prevent the countdown from starting.
   */
  public function cancelEvent():Void
  {
    if (cancelable)
    {
      eventCanceled = true;
    }
  }

  /**
   * Cancel this event.
   * This is an alias for cancelEvent() but I make this typo all the time.
   */
  public function cancel():Void
  {
    cancelEvent();
  }

  /**
   * Call this function to stop any other Scripteds from receiving the event.
   */
  public function stopPropagation():Void
  {
    shouldPropagate = false;
  }

  public function toString():String
  {
    return 'ScriptEvent(type=$type, cancelable=$cancelable)';
  }
}

/**
 * SPECIFIC EVENTS
 */
/**
 * An event that is fired associated with a specific note.
 */
class NoteScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var note(default, null):Note;

  /**
   * The combo count as it is with this event.
   * Will be (combo) on miss events and (combo + 1) on hit events (the stored combo count won't update if the event is cancelled).
   */
  public var comboCount(default, null):Int;

  /**
   * Whether to play the record scratch sound (if this eventn type is `NOTE_MISS`).
   */
  public var playSound(default, default):Bool;

  /**
   * The health gained or lost from this note.
   * This affects both hits and misses. Remember that max health is 2.00.
   */
  public var healthChange:Float;

  public function new(type:ScriptEventType, note:Note, healthChange:Float, comboCount:Int = 0, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.note = note;
    this.comboCount = comboCount;
    this.playSound = true;
    this.healthChange = healthChange;
  }

  public override function toString():String
  {
    return 'NoteScriptEvent(type=' + type + ', cancelable=' + cancelable + ', note=' + note + ', comboCount=' + comboCount + ')';
  }
}

class HitNoteScriptEvent extends NoteScriptEvent
{
  /**
   * The judgement the player received for hitting the note.
   */
  public var judgement:String;

  /**
   * The score the player received for hitting the note.
   */
  public var score:Int;

  /**
   * If the hit causes a combo break.
   */
  public var isComboBreak:Bool = false;

  /**
   * The time difference when the player hit the note
   */
  public var hitDiff:Float = 0;

  /**
   * If the hit causes a notesplash
   */
  public var doesNotesplash:Bool = false;

  public function new(note:Note, healthChange:Float, score:Int, judgement:String, isComboBreak:Bool, comboCount:Int = 0, hitDiff:Float = 0,
      doesNotesplash:Bool = false):Void
  {
    super(NOTE_HIT, note, healthChange, comboCount, true);
    this.score = score;
    this.judgement = judgement;
    this.isComboBreak = isComboBreak;
    this.doesNotesplash = doesNotesplash;
    this.hitDiff = hitDiff;
  }

  public override function toString():String
  {
    return 'HitNoteScriptEvent(note=' + note + ', comboCount=' + comboCount + ', judgement=' + judgement + ', score=' + score + ', isComboBreak='
      + isComboBreak + ', hitDiff=' + hitDiff + ', doesNotesplash=' + doesNotesplash + ')';
  }
}

/**
 * An event that is fired when you press a key with no note present.
 */
class GhostMissNoteScriptEvent extends ScriptEvent
{
  /**
   * The direction that was mistakenly pressed.
   */
  public var dir(default, null):Int;

  /**
   * Whether there was a note within judgement range when this ghost note was pressed.
   */
  public var hasPossibleNotes(default, null):Bool;

  /**
   * How much health should be lost when this ghost note is pressed.
   * Remember that max health is 2.00.
   */
  public var healthChange(default, default):Float;

  /**
   * How much score should be lost when this ghost note is pressed.
   */
  public var scoreChange(default, default):Int;

  /**
   * Whether to play the record scratch sound.
   */
  public var playSound(default, default):Bool;

  /**
   * Whether to play the miss animation on the player.
   */
  public var playAnim(default, default):Bool;

  public function new(dir:Int, hasPossibleNotes:Bool, healthChange:Float, scoreChange:Int):Void
  {
    super(NOTE_GHOST_MISS, true);
    this.dir = dir;
    this.hasPossibleNotes = hasPossibleNotes;
    this.healthChange = healthChange;
    this.scoreChange = scoreChange;
    this.playSound = true;
    this.playAnim = true;
  }

  public override function toString():String
  {
    return 'GhostMissNoteScriptEvent(dir=' + dir + ', hasPossibleNotes=' + hasPossibleNotes + ')';
  }
}

/**
 * An event that is fired during the update loop.
 */
class UpdateScriptEvent extends ScriptEvent
{
  /**
   * The note associated with this event.
   * You cannot replace it, but you can edit it.
   */
  public var elapsed(default, null):Float;

  public function new(elapsed:Float):Void
  {
    super(UPDATE, false);
    this.elapsed = elapsed;
  }

  public override function toString():String
  {
    return 'UpdateScriptEvent(elapsed=$elapsed)';
  }
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class SongTimeScriptEvent extends ScriptEvent
{
  /**
   * The current beat of the song.
   */
  public var beat(default, null):Int;

  /**
   * The current step of the song.
   */
  public var step(default, null):Int;

  public function new(type:ScriptEventType, beat:Int, step:Int):Void
  {
    super(type, true);
    this.beat = beat;
    this.step = step;
  }

  public override function toString():String
  {
    return 'SongTimeScriptEvent(type=' + type + ', beat=' + beat + ', step=' + step + ')';
  }
}

/**
 * An event that is fired regularly during the song.
 * May be on beat or on step.
 */
class CountdownScriptEvent extends ScriptEvent
{
  /**
   * The current step of the countdown.
   */
  public var step(default, null):CountdownStep;

  public function new(type:ScriptEventType, step:CountdownStep, cancelable:Bool = true):Void
  {
    super(type, cancelable);
    this.step = step;
  }

  public override function toString():String
  {
    return 'CountdownScriptEvent(type=' + type + ', step=' + step + ')';
  }
}

/**
 * An event that is fired when the player presses a key.
 */
class KeyboardInputScriptEvent extends ScriptEvent
{
  /**
   * The associated keyboard event.
   */
  public var event(default, null):KeyboardEvent;

  public function new(type:ScriptEventType, event:KeyboardEvent):Void
  {
    super(type, false);
    this.event = event;
  }

  public override function toString():String
  {
    return 'KeyboardInputScriptEvent(type=' + type + ', event=' + event + ')';
  }
}

/**
 * An event that is fired when moving out of or into an FlxState.
 */
class StateChangeScriptEvent extends ScriptEvent
{
  /**
   * The state the game is moving into.
   */
  public var targetState(default, null):FlxState;

  public function new(type:ScriptEventType, targetState:FlxState, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.targetState = targetState;
  }

  public override function toString():String
  {
    return 'StateChangeScriptEvent(type=' + type + ', targetState=' + targetState + ')';
  }
}

/**
 * An event that is fired when moving out of or into an FlxSubState.
 */
class SubStateScriptEvent extends ScriptEvent
{
  /**
   * The state the game is moving into.
   */
  public var targetState(default, null):FlxSubState;

  public function new(type:ScriptEventType, targetState:FlxSubState, cancelable:Bool = false):Void
  {
    super(type, cancelable);
    this.targetState = targetState;
  }

  public override function toString():String
  {
    return 'SubStateScriptEvent(type=' + type + ', targetState=' + targetState + ')';
  }
}

/**
 * An event which is called when the player attempts to pause the game.
 */
class PauseScriptEvent extends ScriptEvent
{
  /**
   * Whether to use the Gitaroo Man pause.
   */
  public var gitaroo(default, default):Bool;

  public function new(gitaroo:Bool):Void
  {
    super(PAUSE, true);
    this.gitaroo = gitaroo;
  }
}
