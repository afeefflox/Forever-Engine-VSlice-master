package meta.subState;

class MusicBeatSubState extends FlxSubState
{
    public function new(?bgColor:FlxColor = FlxColor.TRANSPARENT)
	{
		super();
		this.bgColor = bgColor;

		subStateOpened.add(onOpenSubStateComplete);
		subStateClosed.add(onCloseSubStateComplete);

		Conductor.beatHit.add(this.beatHit);
		Conductor.stepHit.add(this.stepHit);
	}

	public override function destroy():Void
	{
		super.destroy();
		Conductor.beatHit.remove(this.beatHit);
		Conductor.stepHit.remove(this.stepHit);
	}

	private var controls(get, never):Controls;
	inline function get_controls():Controls return PlayerSettings.player1.controls;

	// class 'step' event
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	public function stepHit():Void
	{
		var event = new SongTimeScriptEvent(SONG_STEP_HIT, Conductor.instance.currentBeat, Conductor.instance.currentStep);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;
	}

	public function beatHit():Void
	{
		var event = new SongTimeScriptEvent(SONG_BEAT_HIT, Conductor.instance.currentBeat, Conductor.instance.currentStep);

		dispatchEvent(event);
	
		if (event.eventCanceled) return;
	}

	public function dispatchEvent(event:ScriptEvent) ModuleHandler.callEvent(event);

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

	function onOpenSubStateComplete(targetState:FlxSubState):Void
	{
		dispatchEvent(new SubStateScriptEvent(SUBSTATE_OPEN_END, targetState, true));
	}

	function onCloseSubStateComplete(targetState:FlxSubState):Void
	{
		dispatchEvent(new SubStateScriptEvent(SUBSTATE_CLOSE_END, targetState, true));

	}

	public function refresh() sort(SortUtil.byZIndex, FlxSort.ASCENDING);
}