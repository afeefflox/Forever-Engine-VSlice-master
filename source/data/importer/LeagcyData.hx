package data.importer;
import haxe.ds.Either;
class LeagcyData
{
    public var song:LegacySongData;
}

class LegacySongData
{
  public var player1:String; // Boyfriend
  public var player2:String; // Opponent

  @:jcustomparse(data.DataParse.eitherLegacyScrollSpeeds)
  public var speed:Either<Float, LegacyScrollSpeeds>;
  @:optional
  public var stage:Null<String>;
  @:optional
  public var gfVersion:Null<String>;
  public var bpm:Float;

  @:jcustomparse(data.DataParse.eitherLegacyNoteData)
  public var notes:Either<Array<LegacyNoteSection>, LegacyNoteData>;
  public var song:String; // Song name

  public function new() {}

  public function toString():String
  {
    var notesStr:String = switch (notes)
    {
      case Left(sections): 'single difficulty w/ ${sections.length} sections';
      case Right(data):
        var difficultyCount:Int = 0;
        if (data.easy != null) difficultyCount++;
        if (data.normal != null) difficultyCount++;
        if (data.hard != null) difficultyCount++;
        '${difficultyCount} difficulties';
    };
    return 'LegacySongData($player1, $player2, $notesStr)';
  }
}

typedef LegacyScrollSpeeds =
{
  public var ?easy:Float;
  public var ?normal:Float;
  public var ?hard:Float;
};

typedef LegacyNoteData =
{
  public var ?easy:Array<LegacyNoteSection>;
  public var ?normal:Array<LegacyNoteSection>;
  public var ?hard:Array<LegacyNoteSection>;
};

typedef LegacyNoteSection =
{
    public var mustHitSection:Bool;
    public var sectionNotes:Array<LegacyNote>;
    // BPM changes
    public var ?changeBPM:Bool;
    public var ?bpm:Float;
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