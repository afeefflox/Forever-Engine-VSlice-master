package data.importer;

class CharacterManifestData
{
    public static final CHARACTER_MANIFEST_DATA_VERSION:thx.semver.Version = "1.0.0";

    @:default(data.importer.CharacterManifestData.CHARACTER_MANIFEST_DATA_VERSION)
    @:jcustomparse(data.DataParse.semverVersion)
    @:jcustomwrite(data.DataWrite.semverVersion)
    public var version:thx.semver.Version;

    public var charID:String;

    public function new(charID:String)
    {
        this.version = CHARACTER_MANIFEST_DATA_VERSION;
        this.charID = charID;
    }

    public function getCharacterFileName(?charID:String):String
    {
        return '$charID.${Constants.EXT_DATA}';
    }

    public function getCharacterImageName(?charID:String):String
    {
        return '$charID.png';
    }

    public function serialize(pretty:Bool = true):String
    {
        updateVersionToLatest();

        var writer = new json2object.JsonWriter<CharacterManifestData>();
        return writer.write(this, pretty ? '  ' : null);
    }

    public function updateVersionToLatest():Void 
    {
        this.version = CHARACTER_MANIFEST_DATA_VERSION;
    }

    public static function deserialize(contents:String):Null<CharacterManifestData>
    {
        var parser = new json2object.JsonParser<CharacterManifestData>();
        parser.ignoreUnknownVariables = false;
        parser.fromJson(contents, 'manifest.json');
    
        if (parser.errors.length > 0)
        {
          trace('[ChartManifest] Failed to parse chart file manifest');
    
          for (error in parser.errors)
            DataError.printError(error);
    
          return null;
        }
        return parser.value;
    }
}