package gameObjects.stage;

import meta.modding.events.ScriptEvent;
import meta.modding.IScriptedClass.IStateStageProp;

class StageProp extends FunkinSprite implements IStateStageProp
{
  /**
   * An internal name for this prop.
   */
  public var name:String = '';

  public function new()
  {
    super();
  }

  /**
   * Called when this prop is added to the stage.
   * @param event
   */
  public function onAdd(event:ScriptEvent):Void {}

  public function onScriptEvent(event:ScriptEvent) {}

  public function onCreate(event:ScriptEvent) {}

  public function onDestroy(event:ScriptEvent) {}

  public function onUpdate(event:UpdateScriptEvent) {}
}
