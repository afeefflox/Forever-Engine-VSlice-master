package meta.data;

class PlayStatePlaylist
{
    public static var isStoryMode:Bool = false;
    public static var playlistSongIds:Array<String> = [];
    public static var campaignScore:Int = 0;
    public static var campaignTitle:String = 'UNKNOWN';
    public static var campaignId:Null<String> = null;
    public static var campaignDifficulty:String = Constants.DEFAULT_DIFFICULTY;

    public static function reset():Void
    {
        isStoryMode = false;
        playlistSongIds = [];
        campaignScore = 0;
        campaignTitle = 'UNKNOWN';
        campaignId = null;
        campaignDifficulty = Constants.DEFAULT_DIFFICULTY;
    }
}

typedef PlayStateParams = {
    targetSong:Song,
    ?targetDifficulty:String,
    ?targetVariation:String,
    ?targetInstrumental:String,
    ?practiceMode:Bool,
    ?botPlayMode:Bool,
    ?minimalMode:Bool,
    ?startTimestamp:Float,
    ?playbackRate:Float,
    ?overrideMusic:Bool,
    ?cameraFollowPoint:FlxPoint,
}