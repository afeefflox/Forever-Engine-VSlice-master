package data.registry;
import meta.data.ScriptedFreeplayStyle;
class FreeplayStyleRegistry extends BaseRegistry<FreeplayStyle, FreeplayStyleData>
{
    public static final FREEPLAYSTYLE_DATA_VERSION:thx.semver.Version = '1.0.0';

    public static final FREEPLAYSTYLE_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';
  
    public static final instance:FreeplayStyleRegistry = new FreeplayStyleRegistry();
  
    public function new() 
    {
        super('FREEPLAYSTYLE', 'ui/freeplay/styles', FREEPLAYSTYLE_DATA_VERSION_RULE);
    }

    public function parseEntryData(id:String):Null<FreeplayStyleData>
    {
        var parser:json2object.JsonParser<FreeplayStyleData> = new json2object.JsonParser<FreeplayStyleData>();
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

    public function parseEntryDataRaw(contents:String, ?fileName:String):Null<FreeplayStyleData>
    {
        var parser:json2object.JsonParser<FreeplayStyleData> = new json2object.JsonParser<FreeplayStyleData>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(contents, fileName);
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, fileName);
          return null;
        }
        return parser.value;
    }

    function createScriptedEntry(clsName:String):FreeplayStyle return ScriptedFreeplayStyle.init(clsName, 'unknown');
    function getScriptedClassNames():Array<String> return ScriptedFreeplayStyle.listScriptClasses();
}