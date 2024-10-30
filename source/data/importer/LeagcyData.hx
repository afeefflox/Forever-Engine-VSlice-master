package data.importer;

class LeagcyData
{
    public var song:LegacySongData;
}

class LegacySongData
{
    public var song:String;
	public var notes:Array<LegacySection>;
	public var bpm:Float;
	public var speed:Float;

    public var stage:String;
	public var player1:String;
	public var player2:String;
    public var gfVersion:String;
}

class LegacySection 
{
    public var sectionNotes:Array<LegacyNote>;
	public var mustHitSection:Bool;
	public var bpm:Float;
	public var changeBPM:Bool;
    public var altAnim:Bool;
}

@:jcustomparse(data.DataParse.legacyNote)
class LegacyNote
{
    public var time:Float;
    public var data:Int;
    public var length:Float;
    public var type:String;

    public function new(time:Float, data:Int, ?length:Float, ?type:String)
    {
        this.time = time;
        this.data = data;
        this.length = length ?? 0.0;
        this.type = type;
    }
}