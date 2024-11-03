package data.importer;
import haxe.ds.Either;
import data.importer.LeagcyData.LegacyScrollSpeeds;
import data.importer.LeagcyData.LegacyNoteSection;
import data.importer.LeagcyData.LegacyNoteData;
class MaruData
{
    public var song:MaruSongData;
}

class MaruSongData 
{
    public var song:String;

    @:jcustomparse(data.DataParse.eitherLegacyScrollSpeeds)
    public var speed:Either<Float, LegacyScrollSpeeds>;
    
    @:jcustomparse(data.DataParse.eitherLegacyNoteData)
    public var notes:Either<Array<LegacyNoteSection>, LegacyNoteData>;
    
	public var bpm:Float;
    public var stage:String;
    public var players:Array<String>;
}