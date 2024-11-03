package data;

class SongEventSchema {
    static final NO_SPACE_UNITS:Array<String> = ['x', '°', '%'];

    public var fields:SongEventSchemaRaw;
    public function new(?fields:SongEventSchemaRaw)
    {
        this.fields = fields;
    }

    public function getByName(name:String):SongEventSchemaField
    {
        for (field in fields) if (field.name == name) return field;
        return null;
    }

    public function getFirstField():SongEventSchemaField return fields[0];

    public inline function get(key:Int) return fields[key];

    public inline function arrayWrite(key:Int, value:SongEventSchemaField):SongEventSchemaField  return fields[key] = value;

    public function stringifyFieldValue(name:String, value:Dynamic, addUnits:Bool = true):String
    {
        var field:SongEventSchemaField = getByName(name);
        if (field == null) return 'Unknown';
    
        switch (field.type)
        {
            case SongEventFieldType.STRING, SongEventFieldType.BOOL, SongEventFieldType.CHARACTER:
                return Std.string(value);
            case SongEventFieldType.INTEGER:
                var returnValue:String = Std.string(value);
                if (addUnits) return addUnitsToString(returnValue, field);
                return returnValue;
            case SongEventFieldType.FLOAT:
                var returnValue:String = Std.string(value);
                if (addUnits) return addUnitsToString(returnValue, field);
                return returnValue;
            case SongEventFieldType.ENUM:
                var valueString:String = Std.string(value);
                for (key in field.keys.keys())
                {
                    if (Std.string(field.keys.get(key)) == valueString) return key;
                }
                return valueString;
            default:
                return 'Unknown';
        }
    }
    
    function addUnitsToString(value:String, field:SongEventSchemaField)
    {
        if (field.units == null || field.units == '') return value;
        var unit:String = field.units;
        return value + (NO_SPACE_UNITS.contains(unit) ? '' : ' ') + '${unit}';
    }
}

typedef SongEventSchemaRaw = Array<SongEventSchemaField>;

typedef SongEventSchemaField =
{
    name:String,
    title:String,
    type:SongEventFieldType,
    ?keys:Map<String, Dynamic>,
    ?min:Float,
    ?max:Float,
    ?step:Float,
    ?units:String,
    ?defaultValue:Dynamic,
}

enum abstract SongEventFieldType(String) from String to String
{
    var STRING = "string";
    var INTEGER = "integer";
    var FLOAT = "float";
    var BOOL = "bool";
    var ENUM = "enum";
    var CHARACTER = "character";
}