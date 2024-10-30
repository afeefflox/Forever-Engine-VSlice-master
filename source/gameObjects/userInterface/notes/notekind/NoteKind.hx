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

   public var params:Array<NoteKindParam>;

   public function new(noteKind:String, description:String = "", ?noteStyleId:String, ?params:Array<NoteKindParam>)
    {
      this.noteKind = noteKind;
      this.description = description;
      this.noteStyleId = noteStyleId;
      this.params = params ?? [];
    }

    public function toString():String
        return noteKind;

    function getNotes():Array<NoteSprite>
      {
        var allNotes:Array<NoteSprite> = PlayState.instance.playerStrumline.notes.members.concat(PlayState.instance.opponentStrumline.notes.members);
        return allNotes.filter(function(note:NoteSprite) {
          return note != null && note.noteData.kind == this.noteKind;
        });
      }

    public function onScriptEvent(event:ScriptEvent):Void {}

    public function onCreate(event:ScriptEvent):Void {}
  
    public function onDestroy(event:ScriptEvent):Void {}
  
    public function onUpdate(event:UpdateScriptEvent):Void {}
  
    public function onNoteIncoming(event:NoteScriptEvent):Void {}
  
    public function onNoteHit(event:HitNoteScriptEvent):Void {}
  
    public function onNoteMiss(event:NoteScriptEvent):Void {}
}

abstract NoteKindParamType(String) from String to String
{
  public static final STRING:String = 'String';

  public static final INT:String = 'Int';

  public static final FLOAT:String = 'Float';
}

typedef NoteKindParamData =
{
  ?min:Null<Float>,
  ?max:Null<Float>,
  ?step:Null<Float>,
  ?precision:Null<Int>,
  ?defaultValue:Dynamic
}
typedef NoteKindParam =
{
  name:String,
  description:String,
  type:NoteKindParamType,
  ?data:NoteKindParamData
}