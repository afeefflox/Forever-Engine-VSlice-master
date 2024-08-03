package meta;

import openfl.utils.Assets;
import meta.state.PlayState;

using StringTools;

#if sys
import sys.FileSystem;
#end

class CoolUtil
{
	public static var difficultyLength = Constants.DEFAULT_DIFFICULTY_LIST.length;

	public static inline function difficultyFromNumber(number:Int):String
	{
		return Constants.DEFAULT_DIFFICULTY_LIST[number];
	}

	public static inline function dashToSpace(string:String):String
	{
		return string.replace("-", " ");
	}

	public static inline function spaceToDash(string:String):String
	{
		return string.replace(" ", "-");
	}

	public static inline function swapSpaceDash(string:String):String
	{
		return string.contains('-') ? dashToSpace(string) : spaceToDash(string);
	}

	public static inline function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = Assets.getText(path).trim().split('\n');
		for (i in 0...daList.length)
			daList[i] = daList[i].trim();
		return daList;
	}

	public static inline function returnAssetsLibrary(library:String, ?subDir:String = 'assets/images'):Array<String>
	{
		var libraryArray:Array<String> = [];

		#if sys
		var unfilteredLibrary = FileSystem.readDirectory('$subDir/$library');

		for (folder in unfilteredLibrary)
		{
			if (!folder.contains('.'))
				libraryArray.push(folder);
		}
		//trace(libraryArray);
		#end

		return libraryArray;
	}

	public static inline function getAnimsFromTxt(path:String):Array<Array<String>>
	{
		var fullText:String = Assets.getText(path);
		var firstArray:Array<String> = fullText.split('\n');
		var swagOffsets:Array<Array<String>> = [];

		for (i in firstArray)
			swagOffsets.push(i.split('--'));
		return swagOffsets;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		return [for (i in min...max) i];
	}

	public static function buildVoiceList(SONG:SwagSong, ?suffix:String = ""):Array<String>
	{
		var playerId:String = SONG.characters[0];
		var voicePlayer:String = Paths.voices(SONG.song, '-$playerId$suffix');
		while (voicePlayer != null && !Paths.exists(voicePlayer))
		{
		  // Remove the last suffix.
		  // For example, bf-car becomes bf.
		  playerId = playerId.split('-').slice(0, -1).join('-');
		  // Try again.
		  voicePlayer = playerId == '' ? null : Paths.voices(SONG.song, '-${playerId}$suffix');
		}
		if (voicePlayer == null)
		{
		  // Try again without $suffix.
		  playerId = SONG.characters[0];
		  voicePlayer = Paths.voices(SONG.song, '-${playerId}');
		  while (voicePlayer != null && !Paths.exists(voicePlayer))
		  {
			// Remove the last suffix.
			playerId = playerId.split('-').slice(0, -1).join('-');
			// Try again.
			voicePlayer = playerId == '' ? null : Paths.voices(SONG.song, '-${playerId}$suffix');
		  }
		}
	
		var opponentId:String = SONG.characters[1];
		var voiceOpponent:String = Paths.voices(SONG.song, '-${opponentId}$suffix');
		while (voiceOpponent != null && !Paths.exists(voiceOpponent))
		{
		  // Remove the last suffix.
		  opponentId = opponentId.split('-').slice(0, -1).join('-');
		  // Try again.
		  voiceOpponent = opponentId == '' ? null : Paths.voices(SONG.song, '-${opponentId}$suffix');
		}
		if (voiceOpponent == null)
		{
		  // Try again without $suffix.
		  opponentId = SONG.characters[1];
		  voiceOpponent = Paths.voices(SONG.song, '-${opponentId}');
		  while (voiceOpponent != null && !Paths.exists(voiceOpponent))
		  {
			// Remove the last suffix.
			opponentId = opponentId.split('-').slice(0, -1).join('-');
			// Try again.
			voiceOpponent = opponentId == '' ? null : Paths.voices(SONG.song, '-${opponentId}$suffix');
		  }
		}
	
		var result:Array<String> = [];
		if (voicePlayer != null) result.push(voicePlayer);
		if (voiceOpponent != null) result.push(voiceOpponent);
		if (voicePlayer == null && voiceOpponent == null)
		{
		  // Try to use `Voices.ogg` if no other voices are found.
		  if(Paths.exists(Paths.voices(SONG.song, '-bf$suffix'))) result.push(Paths.voices(SONG.song, '-bf$suffix'));
		  if(Paths.exists(Paths.voices(SONG.song, '-dad$suffix'))) result.push(Paths.voices(SONG.song, '-dad$suffix'));

		  if(Paths.exists(Paths.voices(SONG.song, '-player$suffix'))) result.push(Paths.voices(SONG.song, '-player$suffix'));
		  if(Paths.exists(Paths.voices(SONG.song, '-opponent$suffix'))) result.push(Paths.voices(SONG.song, '-opponent$suffix'));	
		  if(Paths.exists(Paths.voices(SONG.song, '$suffix'))) result.push(Paths.voices(SONG.song, '$suffix'));		  	  

		}
		trace('result: $result');
		return result;
	}
}
