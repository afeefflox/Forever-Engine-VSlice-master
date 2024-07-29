package data.registry;

import data.NoteTypeData;
import meta.data.noteCustom.NoteCustom;
import meta.data.noteCustom.NoteCustomScripted;

class NoteTypeRegistry extends BaseRegistry<NoteCustom, NoteTypeData>
{
    public static final NOTETYPE_DATA_VERSION:thx.semver.Version = "1.0.0";

    public static final NOTETYPE_DATA_VERSION_RULE:thx.semver.VersionRule = "1.0.x";

    public static var instance(get, never):NoteTypeRegistry;
    static var _instance:Null<NoteTypeRegistry> = null;
  
    static function get_instance():NoteTypeRegistry
    {
      if (_instance == null) _instance = new NoteTypeRegistry();
      return _instance;
    }
  
    public function new()
    {
      super('NOTETYPE', 'notetypes', NOTETYPE_DATA_VERSION_RULE);
    }    


    /**
    * Read, parse, and validate the JSON data and produce the corresponding data object.
    */
    public function parseEntryData(id:String):Null<NoteTypeData>
    {
      // JsonParser does not take type parameters,
      // otherwise this function would be in BaseRegistry.
      var parser = new json2object.JsonParser<NoteTypeData>();
      parser.ignoreUnknownVariables = true;
  
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
  
    /**
     * Parse and validate the JSON data and produce the corresponding data object.
     *
     * NOTE: Must be implemented on the implementation class.
     * @param contents The JSON as a string.
     * @param fileName An optional file name for error reporting.
     */
    public function parseEntryDataRaw(contents:String, ?fileName:String):Null<NoteTypeData>
    {
      var parser = new json2object.JsonParser<NoteTypeData>();
      parser.ignoreUnknownVariables = true;
      parser.fromJson(contents, fileName);
  
      if (parser.errors.length > 0)
      {
        printErrors(parser.errors, fileName);
        return null;
      }
      return parser.value;
    }
  
    function createScriptedEntry(clsName:String):NoteCustom
    {
      return NoteCustomScripted.init(clsName, "unknown");
    }
    
    function getScriptedClassNames():Array<String>
    {
      return NoteCustomScripted.listScriptClasses();
    }
}