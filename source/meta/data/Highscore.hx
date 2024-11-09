package meta.data;

import flixel.FlxG;
import flixel.util.FlxSave;
using StringTools;

class Highscore
{
	public var tallies:Tallies = new Tallies();
	public var talliesLevel:Tallies = new Tallies();
	public var songData:FlxSave;

	var highscoreData:SaveHighScoresData;

	public static var instance(get, never):Highscore;
	static var _instance:Null<Highscore> = null;

	static function get_instance():Highscore
	{
		if (_instance == null) _instance = new Highscore();
        return _instance;
	}

	public function new ()
	{
		tallies = new Tallies();
		songData = new FlxSave();
		songData.bind('songData_save', CoolUtil.getSavePath());
		highscoreData = {
			songs: [],
			levels: []
		}
		if(songData.data.scores == null) 
			songData.data.scores = highscoreData;
		else
			highscoreData = songData.data.scores;
	}

	public function combineTallies(newTally:Tallies, baseTally:Tallies):Tallies
	{
		var combinedTally:Tallies = new Tallies();
		combinedTally.missed = newTally.missed + baseTally.missed;
		combinedTally.shit = newTally.shit + baseTally.shit;
		combinedTally.bad = newTally.bad + baseTally.bad;
		combinedTally.good = newTally.good + baseTally.good;
		combinedTally.sick = newTally.sick + baseTally.sick;
		combinedTally.totalNotes = newTally.totalNotes + baseTally.totalNotes;
		combinedTally.totalNotesHit = newTally.totalNotesHit + baseTally.totalNotesHit;
		combinedTally.combo = newTally.combo;
		combinedTally.maxCombo = Std.int(Math.max(newTally.maxCombo, baseTally.maxCombo));
		return combinedTally;
	}


	public function getLevelScore(levelId:String, difficultyId:String = 'normal'):Null<SaveScoreData>
	{
		highscoreData.levels = [];
		var level = highscoreData.levels.get(levelId);
		if (level == null)
		{
			level = [];
			highscoreData.levels.set(levelId, level);
		}
		return level.get(difficultyId);
	}

	public function setLevelScore(levelId:String, difficultyId:String, score:SaveScoreData):Void
	{
		var level = highscoreData.levels.get(levelId);
		if (level == null)
		{
		  level = [];
		  highscoreData.levels.set(levelId, level);
		}
		level.set(difficultyId, score);

		songData.data.scores = highscoreData;
	
		songData.flush();
	}

	public function isLevelHighScore(levelId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
	{
		var level = highscoreData.levels.get(levelId);
		if (level == null)
		{
		  level = [];
		  highscoreData.levels.set(levelId, level);
		}
	
		var currentScore = level.get(difficultyId);
		if (currentScore == null)
		{
		  return true;
		}
	
		return score.score > currentScore.score;
	}

	public function hasBeatenLevel(levelId:String, ?difficultyList:Array<String>):Bool
	{
		if (difficultyList == null) difficultyList = ['easy', 'normal', 'hard'];

		for (difficulty in difficultyList)
		{
			var score:Null<SaveScoreData> = getLevelScore(levelId, difficulty);
			if (score != null) 
				return score.score > 0;
		}
		return false;
	}

	public function getSongScore(songId:String, difficultyId:String = 'normal', ?variation:String):Null<SaveScoreData>
	{
		var song = highscoreData.songs.get(songId);
		trace('Getting song score for $songId $difficultyId $variation');
		if (song == null)
		{
			trace('Could not find song data for $songId $difficultyId $variation');
			song = [];
			highscoreData.songs.set(songId, song);
		}

		if (variation != null && variation != '' && variation != 'default' && variation != 'erect')
			difficultyId = '${difficultyId}-${variation}';

		return song.get(difficultyId);
	}

	public function getSongRank(songId:String, difficultyId:String = 'normal', ?variation:String):Null<ScoringRank>
	{
		return Scoring.calculateRank(getSongScore(songId, difficultyId, variation));
	}

	public function setSongScore(songId:String, difficultyId:String, score:SaveScoreData):Void
	{
		var song = highscoreData.songs.get(songId);
		if (song == null)
		{
		  song = [];
		  highscoreData.songs.set(songId, song);
		}
		song.set(difficultyId, score);
		songData.data.scores = highscoreData;
		songData.flush();
	}

	public function applySongRank(songId:String, difficultyId:String, newScoreData:SaveScoreData):Void
	{
		var newRank = Scoring.calculateRank(newScoreData);
		if (newScoreData == null || newRank == null) return;
	
		var song = highscoreData.songs.get(songId);
		if (song == null)
		{
			song = [];
			highscoreData.songs.set(songId, song);
		}
	
		var previousScoreData = song.get(difficultyId);
	
		var previousRank = Scoring.calculateRank(previousScoreData);

		if (previousScoreData == null || previousRank == null)
		{
			setSongScore(songId, difficultyId, newScoreData);
			return;
		}

		var newCompletion = (newScoreData.tallies.sick + newScoreData.tallies.good) / newScoreData.tallies.totalNotes;
		var previousCompletion = (previousScoreData.tallies.sick + previousScoreData.tallies.good) / previousScoreData.tallies.totalNotes;

		var newScore:SaveScoreData =
		{
		  score: (previousScoreData.score > newScoreData.score) ? previousScoreData.score : newScoreData.score,
		  tallies: (previousRank > newRank || previousCompletion > newCompletion) ? previousScoreData.tallies : newScoreData.tallies
		};
  
		
		song.set(difficultyId, newScore);
		songData.data.scores = highscoreData;
		songData.flush();	
	}

	public function isSongHighScore(songId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
	{
		var song = highscoreData.songs.get(songId);
		if (song == null)
		{
		  song = [];
		  highscoreData.songs.set(songId, song);
		}
	
		var currentScore = song.get(difficultyId);
		if (currentScore == null)
		{
		  return true;
		}
	
		return score.score > currentScore.score;
	}

	public function isSongHighRank(songId:String, difficultyId:String = 'normal', score:SaveScoreData):Bool
	{
		var newScoreRank = Scoring.calculateRank(score);
		if (newScoreRank == null) return false;


		var song = highscoreData.songs.get(songId);
		if (song == null)
		{
			song = [];
			highscoreData.songs.set(songId, song);
		}
		var currentScore = song.get(difficultyId);
		var currentScoreRank = Scoring.calculateRank(currentScore);
		if (currentScoreRank == null) return true;
		return newScoreRank > currentScoreRank;
	}

	public function hasBeatenSong(songId:String, ?difficultyList:Array<String>, ?variation:String):Bool
	{
		if (difficultyList == null)
			difficultyList = ['easy', 'normal', 'hard'];

		if (variation == null) variation = '';

		for (difficulty in difficultyList)
		{
			if (variation != '') difficulty = '${difficulty}-${variation}';

			var score:Null<SaveScoreData> = getSongScore(songId, difficulty);
			if (score != null)
				return score.score > 0;
			return false;
		}
		return false;
	}

	public function isSongFavorited(id:String):Bool
	{
		if (songData.data.favorite == null)
		{
			songData.data.favorite = [];
			songData.flush();
		};
		
		return songData.data.favorite.contains(id);
	}

	
	public function favoriteSong(id:String):Void
	{
		if (!isSongFavorited(id))
		{
			songData.data.favorite.push(id);
			songData.flush();
		}
	}

	public function unfavoriteSong(id:String):Void
	{
		if (isSongFavorited(id))
		{
			songData.data.favorite.remove(id);
			songData.data.flush();
		}
	}
}

typedef SaveHighScoresData = {
	var levels:SaveScoreLevelsData;
	var songs:SaveScoreSongsData;
}

typedef SaveScoreLevelsData = Map<String, SaveScoreDifficultiesData>;
typedef SaveScoreSongsData = Map<String, SaveScoreDifficultiesData>;
typedef SaveScoreDifficultiesData = Map<String, SaveScoreData>;


typedef SaveScoreData =
{
	var score:Int;
	var tallies:SaveScoreTallyData;
}

typedef SaveScoreTallyData =
{
  var sick:Int;
  var good:Int;
  var bad:Int;
  var shit:Int;
  var missed:Int;
  var combo:Int;
  var maxCombo:Int;
  var totalNotesHit:Int;
  var totalNotes:Int;
}

@:forward
abstract Tallies(RawTallies)
{
  public function new()
  {
    this =
      {
        combo: 0,
        missed: 0,
        shit: 0,
        bad: 0,
        good: 0,
        sick: 0,
        totalNotes: 0,
        totalNotesHit: 0,
        maxCombo: 0,
        score: 0,
        isNewHighscore: false
      }
  }
}

/**
 * A structure object containing the data for highscore tallies.
 */
typedef RawTallies =
{
  var combo:Int;

  /**
   * How many notes you let scroll by.
   */
  var missed:Int;

  var shit:Int;
  var bad:Int;
  var good:Int;
  var sick:Int;
  var maxCombo:Int;

  var score:Int;

  var isNewHighscore:Bool;

  /**
   * How many notes total that you hit. (NOT how many notes total in the song!)
   */
  var totalNotesHit:Int;

  /**
   * How many notes in the current chart
   */
  var totalNotes:Int;
}