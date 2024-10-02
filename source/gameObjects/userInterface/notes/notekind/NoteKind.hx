package gameObjects.userInterface.notes.notekind;
import meta.modding.IScriptedClass.INoteScriptedClass;
class NoteKind implements INoteScriptedClass
{
  /**
   * The name of the note kind
   */
   public var noteKind:String;

   /**
    * Description used in chart editor
    */
   public var description:String;
 
   /**
    * Custom note style
    */
   public var noteStyleId:Null<String>;

   public function new(noteKind:String, description:String = "", ?noteStyleId:String)
    {
      this.noteKind = noteKind;
      this.description = description;
      this.noteStyleId = noteStyleId;
    }

    public function toString():String
        return noteKind;

    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}
  
    public function onDestroy(event:ScriptEvent):Void {}
  
    public function onUpdate(event:UpdateScriptEvent):Void {}
  
    public function onNoteIncoming(event:NoteScriptEvent):Void {}
  
    public function onNoteHit(event:HitNoteScriptEvent):Void {}
  
    public function onNoteMiss(event:NoteScriptEvent):Void {}
}