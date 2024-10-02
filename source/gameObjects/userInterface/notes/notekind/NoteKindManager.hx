package gameObjects.userInterface.notes.notekind;
import gameObjects.userInterface.notes.notekind.ScriptedNoteKind;
class NoteKindManager
{
    static var noteKinds:Map<String, NoteKind> = [];

    public static function loadScripts():Void
    {
        var scriptedClassName:Array<String> = ScriptedNoteKind.listScriptClasses();
        if (scriptedClassName.length > 0)
        {
            trace('Instantiating ${scriptedClassName.length} scripted note kind(s)...');
            for (scriptedClass in scriptedClassName)
            {
              try
              {
                var script:NoteKind = ScriptedNoteKind.init(scriptedClass, "unknown");
                trace(' Initialized scripted note kind: ${script.noteKind}');
                noteKinds.set(script.noteKind, script);
                meta.state.editors.ChartingState.NOTE_KINDS.set(script.noteKind, script.description);
              }
              catch (e)
              {
                trace(' FAILED to instantiate scripted note kind: ${scriptedClass}');
                trace(e);
              }
            }
        }
    }

    public static function callEvent(event:ScriptEvent):Void
    {
        // if it is a note script event,
        // then only call the event for the specific note kind script
        if (Std.isOfType(event, NoteScriptEvent))
        {
            var noteEvent:NoteScriptEvent = cast(event, NoteScriptEvent);
      
            var noteKind:NoteKind = noteKinds.get(noteEvent.note.kind);
      
            if (noteKind != null) ScriptEventDispatcher.callEvent(noteKind, event);
        }
        else // call the event for all note kind scripts
        {
            for (noteKind in noteKinds.iterator()) ScriptEventDispatcher.callEvent(noteKind, event);
        }
    }

    public static function getNoteStyle(noteKind:String, ?suffix:String):Null<NoteStyle>
    {
        var noteStyleId:Null<String> = getNoteStyleId(noteKind, suffix);

        if (noteStyleId == null)
        {
          return null;
        }
    
        return NoteStyleRegistry.instance.fetchEntry(noteStyleId);
    }

    public static function getNoteStyleId(noteKind:String, ?suffix:String):Null<String>
    {
        if (suffix == '') suffix = null;
        
        var noteStyleId:Null<String> = noteKinds.get(noteKind)?.noteStyleId;
        if (noteStyleId != null && suffix != null)
            noteStyleId = NoteStyleRegistry.instance.hasEntry('$noteStyleId-$suffix') ? '$noteStyleId-$suffix' : noteStyleId;
        
        return noteStyleId;
    }

    public static function getNotekinds(idk:String) {
        return noteKinds.get(idk);
    }
}