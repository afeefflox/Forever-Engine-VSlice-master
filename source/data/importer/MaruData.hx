package data.importer;

import data.importer.LeagcyData.LegacyNote;
class MaruData
{
    public var song:MaruSongData;
}

class MaruSongData
{
    public var song:String;
	public var notes:Array<MaruSection>;
	public var bpm:Float;
	public var speed:Float;
    public var stage:String;
    public var players:Array<String>;
}

class MaruSection
{
    public var sectionNotes:Array<LegacyNote>;
	public var mustHitSection:Bool;
	public var bpm:Float;
	public var changeBPM:Bool;
}