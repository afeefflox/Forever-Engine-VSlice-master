package meta.subState;

class MusicBeatSubState extends FlxSubState
{
    public function new(?bgColor:FlxColor = FlxColor.TRANSPARENT)
	{
		super();
		this.bgColor = bgColor;
	}

	/**
	 * Array of notes showing when each measure/bar STARTS in STEPS
	 * Usually rounded up??
	 */
	public var curBar: Int = 0;
	public var curBeat:Int = 0;
	public var curStep:Int = 0;

	function updateBar() curBar = Math.floor(curBeat * 0.25);
	function updateBeat() curBeat = Math.floor(curStep * 0.25);

	private var controls(get, never):Controls;
	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	// class 'step' event
	override function update(elapsed:Float)
	{
		updateContents();

		super.update(elapsed);

		// Emergency exit button.
		if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new MainMenuState());

		// This can now be used in EVERY STATE YAY!
		if (FlxG.keys.justPressed.F5) debug_refreshModules();
	  
		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	function debug_refreshModules()
	{
		PolymodHandler.forceReloadAssets();
		// Restart the current state, so old data is cleared.
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

		// do literally nothing dumbass
	}

	public function dispatchEvent(event:ScriptEvent)
		ModuleHandler.callEvent(event);
	
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

	public override function closeSubState():Void
	{
		var event = new SubStateScriptEvent(SUBSTATE_CLOSE_BEGIN, this.subState, true);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;
	
		super.closeSubState();
	}

	public function refresh()
	{
		sort(SortUtil.byZIndex, FlxSort.ASCENDING);
	}
}