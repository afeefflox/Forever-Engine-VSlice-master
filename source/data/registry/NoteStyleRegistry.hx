package data.registry;

import gameObjects.userInterface.notes.notestyle.ScriptedNoteStyle;
class NoteStyleRegistry extends BaseRegistry<NoteStyle, NoteStyleData>
{
    public static final NOTE_STYLE_DATA_VERSION:thx.semver.Version = "1.1.0";

    public static final NOTE_STYLE_DATA_VERSION_RULE:thx.semver.VersionRule = "1.1.x";
  
    public static var instance(get, never):NoteStyleRegistry;
    static var _instance:Null<NoteStyleRegistry> = null;
  
    static function get_instance():NoteStyleRegistry
    {
        if (_instance == null) _instance = new NoteStyleRegistry();
        return _instance;
    }

    public function new()
    {
        super('NOTESTYLE', 'notestyles', NOTE_STYLE_DATA_VERSION_RULE);
    }

    public function fetchDefault():NoteStyle
    {
        return fetchEntry(Constants.DEFAULT_NOTE_STYLE);
    }

    public function parseEntryData(id:String):Null<NoteStyleData>
    {
        var parser = new json2object.JsonParser<NoteStyleData>();
        parser.ignoreUnknownVariables = false;
    
        switch (loadEntryFile(id))
        {
          case {fileName: fileName, contents: contents}:
            parser.fromJson(contents, fileName);
          default:
            return null;
        }
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, id);
          return null;
        }
        return parser.value;
    }

    public function parseEntryDataRaw(contents:String, ?fileName:String):Null<NoteStyleData>
    {
        var parser = new json2object.JsonParser<NoteStyleData>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(contents, fileName);
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, fileName);
          return null;
        }
        return parser.value;
    }

    function createScriptedEntry(clsName:String):NoteStyle
        return ScriptedNoteStyle.init(clsName, "unknown");

    function getScriptedClassNames():Array<String>
        return ScriptedNoteStyle.listScriptClasses();



}