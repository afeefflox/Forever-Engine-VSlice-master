package meta.state;

import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;

class MusicBeatState extends FlxUIState implements IEventHandler
{
    public var curBar:Int = 0;

	public var curBeat:Int = 0;
	public var curStep:Int = 0;

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

	// class create event
	override function create()
	{
		// state stuffs
		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FNFTransition(0.5, true));
		
		Conductor.beatHit.add(this.beatHit);
		Conductor.stepHit.add(this.stepHit);

		super.create();
	}

	// class 'step' event
	override function update(elapsed:Float)
	{		
		super.update(elapsed);
		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	public function dispatchEvent(event:ScriptEvent) ModuleHandler.callEvent(event);

	public function refresh() sort(SortUtil.byZIndex, FlxSort.ASCENDING);

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

	public override function destroy():Void
	{
		super.destroy();
		Conductor.beatHit.remove(this.beatHit);
		Conductor.stepHit.remove(this.stepHit);
	}
}