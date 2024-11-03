package meta.data;

import flixel.FlxG;

using StringTools;

class Highscore
{
	public static var songScores:Map<String, Int>;

	public static function saveSongScore(song:String, diff:String, variation:String, score:Int = 0):Void
	{
		variation = (variation != Constants.DEFAULT_VARIATION) ? '-${variation}' : '';

		var daSong:String = formatSave(formatSong(song) + variation, diff);
		if (songScores.exists(daSong)) {
			if (songScores.get(daSong) < score) {
				setScore(daSong, score);
				return;
			}
		}
		setScore(daSong, score);
	}

	public static function saveWeekScore(week:String, diff:String, score:Int = 0):Void
	{
		var daWeek:String = formatSave(formatWeek(week), diff);
		if (songScores.exists(daWeek)) {
			if (songScores.get(daWeek) < score) {
				setScore(daWeek, score);
				return;
			}
		}
		setScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function getScore(song:String, diff:String, variation:String):Int
	{
		variation = (variation != Constants.DEFAULT_VARIATION) ? '-${variation}' : '';

		var daSong:String = formatSave(formatSong(song) + variation, diff);
		if (!songScores.exists(daSong))
			setScore(daSong, 0);
		return songScores.get(daSong);
	}

    public static function getWeekScore(week:String, diff:String):Int
	{

		var daWeek:String = formatSave(formatWeek(week), diff);
		if (!songScores.exists(daWeek))
			setScore(daWeek, 0);
		return songScores.get(daWeek);
	}

	inline static function formatSong(song:String):String return 'song-$song';
	inline static function formatWeek(week:String):String return 'week-$week';
	inline static function formatSave(input:String, diff:String):String return '${input.toLowerCase()}-$diff';

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null) songScores = FlxG.save.data.songScores;
	}
}
