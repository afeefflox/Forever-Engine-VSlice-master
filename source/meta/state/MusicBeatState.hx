package meta.state;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState implements IEventHandler
{
    public var curBar:Int = 0;

	public var curBeat:Int = 0;
	public var curStep:Int = 0;
	public static var cache:Bool = true;

	function updateBar() curBar = Math.floor(curBeat * 0.25);
	function updateBeat() curBeat = Math.floor(curStep * 0.25);

	private var controls(get, never):Controls;
	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public function new() {
		super();

		subStateOpened.add(onOpenSubStateComplete);
		subStateClosed.add(onCloseSubStateComplete);
	}

	function handleFunctionControls():Void
	{
		// Emergency exit button.
		if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new MainMenuState());
	  
		// This can now be used in EVERY STATE YAY!
		if (FlxG.keys.justPressed.F5) debug_refreshModules();
	}

	// class create event
	override function create()
	{
		// dump
		if(cache)
		{
			Paths.clearStoredMemory();
			if (!Std.isOfType(this, meta.state.PlayState) || !Std.isOfType(this, meta.state.editors.ChartingState))
				Paths.clearUnusedMemory();
		}
			


		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FNFTransition(0.5, true));

		/*
		if (transIn != null)
			trace('reg ' + transIn.region);
		*/

		super.create();

		// For debugging
		FlxG.watch.add(Conductor, "songPosition");
		FlxG.watch.add(this, "curBeat");
		FlxG.watch.add(this, "curStep");
	}

	// class 'step' event
	override function update(elapsed:Float)
	{		
		super.update(elapsed);
		updateContents();
		handleFunctionControls();
		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	public function dispatchEvent(event:ScriptEvent)
		ModuleHandler.callEvent(event);

	function debug_refreshModules()
	{
		PolymodHandler.forceReloadAssets();

		this.destroy();
	
		// Create a new instance of the current state, so old data is cleared.
		FlxG.resetState();
	}

	public function updateContents()
	{
		updateCurStep();
		updateBeat();
		updateBar();

		// delta time bullshit
		var trueStep:Int = curStep;
		for (i in storedSteps)
			if (i < oldStep)
				storedSteps.remove(i);
		for (i in oldStep...trueStep)
		{
			if (!storedSteps.contains(i) && i > 0)
			{
				curStep = i;
				stepHit();
				skippedSteps.push(i);
			}
		}
		if (skippedSteps.length > 0)
		{
			//trace('skipped steps $skippedSteps');
			skippedSteps = [];
		}
		curStep = trueStep;

		//
		if (oldStep != curStep && curStep > 0 && !storedSteps.contains(curStep))
			stepHit();
		oldStep = curStep;
	}

	var oldStep:Int = 0;
	var storedSteps:Array<Int> = [];
	var skippedSteps:Array<Int> = [];

	public function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		var event = new SongTimeScriptEvent(SONG_STEP_HIT, curBeat, curStep);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;

		if (curStep % 4 == 0)
			beatHit();

		// trace('step $curStep');
		if (!storedSteps.contains(curStep))
			storedSteps.push(curStep);
		else
			trace('SOMETHING WENT WRONG??? STEP REPEATED $curStep');
	}

	public function beatHit():Void
	{
		var event = new SongTimeScriptEvent(SONG_BEAT_HIT, curBeat, curStep);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;

		// used for updates when beats are hit in classes that extend this one
	}
	override function startOutro(onComplete:() -> Void):Void
	{
		var event = new StateChangeScriptEvent(STATE_CHANGE_BEGIN, null, true);

		dispatchEvent(event);
	
		if (event.eventCanceled)
			return;
		else
			onComplete();
	}

	public override function openSubState(targetSubState:FlxSubState):Void
	{
		var event = new SubStateScriptEvent(SUBSTATE_OPEN_BEGIN, targetSubState, true);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;
	
		super.openSubState(targetSubState);
	}

	function onOpenSubStateComplete(targetState:FlxSubState):Void
		dispatchEvent(new SubStateScriptEvent(SUBSTATE_OPEN_END, targetState, true));

	public override function closeSubState():Void
	{
		var event = new SubStateScriptEvent(SUBSTATE_CLOSE_BEGIN, this.subState, true);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;
	
		super.closeSubState();
	}

	function onCloseSubStateComplete(targetState:FlxSubState):Void
		dispatchEvent(new SubStateScriptEvent(SUBSTATE_CLOSE_END, targetState, true));
}