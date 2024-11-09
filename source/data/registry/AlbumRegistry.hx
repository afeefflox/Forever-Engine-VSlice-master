package data.registry;
import meta.data.ScriptedAlbum;
class AlbumRegistry extends BaseRegistry<Album, AlbumData>
{
    public static final ALBUM_DATA_VERSION:thx.semver.Version = '1.0.0';

    public static final ALBUM_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';
  
    public static final instance:AlbumRegistry = new AlbumRegistry();

    public function new()
    {
        super('ALBUM', 'ui/freeplay/albums', ALBUM_DATA_VERSION_RULE);
    }

    public function parseEntryData(id:String):Null<AlbumData>
    {
        var parser:json2object.JsonParser<AlbumData> = new json2object.JsonParser<AlbumData>();
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

    public function parseEntryDataRaw(contents:String, ?fileName:String):Null<AlbumData>
    {
        var parser:json2object.JsonParser<AlbumData> = new json2object.JsonParser<AlbumData>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(contents, fileName);
    
        if (parser.errors.length > 0)
        {
          printErrors(parser.errors, fileName);
          return null;
        }
        return parser.value;
    }

    function createScriptedEntry(clsName:String):Album return ScriptedAlbum.init(clsName, 'unknown');
    function getScriptedClassNames():Array<String> return ScriptedAlbum.listScriptClasses();
}